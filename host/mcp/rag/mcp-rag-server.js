#!/usr/bin/env node
/**
 * mcp-rag-server.js — MCP Server for Supabase RAG integration
 *
 * Exposes RAG tools to Cursor and VSCode so they can:
 * - Load agent instructions from Supabase at runtime
 * - Save learned knowledge back to Supabase
 *
 * Usage (stdio transport):
 *   node mcp-rag-server.js
 *
 * Env vars:
 *   RAG_DSN      PostgreSQL connection string (Supabase)
 *   RAG_PROJECT  Project scope (default: "global")
 */

const { Client } = require('pg');
const readline = require('readline');

const RAG_DSN = process.env.RAG_DSN;
const RAG_PROJECT = process.env.RAG_PROJECT || 'global';

// ── MCP Protocol helpers ─────────────────────────────────────────────────────

function send(obj) {
  process.stdout.write(JSON.stringify(obj) + '\n');
}

function error(id, code, message) {
  send({ jsonrpc: '2.0', id, error: { code, message } });
}

// ── DB helpers ───────────────────────────────────────────────────────────────

async function query(sql, params = []) {
  if (!RAG_DSN) throw new Error('RAG_DSN environment variable is not set');
  const client = new Client({ connectionString: RAG_DSN });
  await client.connect();
  try {
    const result = await client.query(sql, params);
    return result.rows;
  } finally {
    await client.end();
  }
}

// ── Tool definitions ─────────────────────────────────────────────────────────

const TOOLS = [
  {
    name: 'rag_load',
    description:
      'Load agent instructions from Supabase RAG. Returns sections ordered by type (role → process → best_practices → reference → edge_cases → output_format → learned-skill).',
    inputSchema: {
      type: 'object',
      properties: {
        agent_name: {
          type: 'string',
          description: "Agent name (e.g. 'angular-expert', 'symfony-expert', 'git-smart-commit')",
        },
        project: {
          type: 'string',
          description: "Project scope. Defaults to RAG_PROJECT env var or 'global'.",
        },
      },
      required: ['agent_name'],
    },
  },
  {
    name: 'rag_save_learning',
    description: 'Persist a learned skill or discovery to Supabase RAG. Use after solving a non-trivial problem.',
    inputSchema: {
      type: 'object',
      properties: {
        agent_name: {
          type: 'string',
          description: "Target agent (e.g. 'angular-expert', 'symfony-expert')",
        },
        project: {
          type: 'string',
          description: "'global' for reusable patterns, or project name for project-specific knowledge",
        },
        section_title: {
          type: 'string',
          description: 'Descriptive title for the learned skill',
        },
        content: {
          type: 'string',
          description: 'Full content of the learned skill',
        },
        tags: {
          type: 'array',
          items: { type: 'string' },
          description: 'Optional tags for categorization',
        },
      },
      required: ['agent_name', 'project', 'section_title', 'content'],
    },
  },
  {
    name: 'rag_audit',
    description: 'List all agents and their section counts in Supabase RAG.',
    inputSchema: {
      type: 'object',
      properties: {},
    },
  },
  {
    name: 'rag_search',
    description: 'Search RAG sections by keyword across all agents and projects.',
    inputSchema: {
      type: 'object',
      properties: {
        keyword: {
          type: 'string',
          description: 'Keyword to search in section content',
        },
        project: {
          type: 'string',
          description: 'Optional project filter',
        },
      },
      required: ['keyword'],
    },
  },
];

// ── Tool handlers ────────────────────────────────────────────────────────────

async function handleRagLoad({ agent_name, project }) {
  const proj = project || RAG_PROJECT;
  const rows = await query(
    `SELECT section_type, section_title, content
     FROM rag_agent_instructions
     WHERE agent_name = $1
       AND project IN ('global', $2)
       AND active = true
     ORDER BY CASE section_type
       WHEN 'role'          THEN 1
       WHEN 'process'       THEN 2
       WHEN 'best_practices'THEN 3
       WHEN 'reference'     THEN 4
       WHEN 'edge_cases'    THEN 5
       WHEN 'output_format' THEN 6
       WHEN 'learned-skill' THEN 7
       ELSE 8
     END, section_title`,
    [agent_name, proj]
  );

  if (rows.length === 0) {
    return `No instructions found for agent '${agent_name}' in project '${proj}' or 'global'.`;
  }

  return rows.map((r) => `## ${r.section_title || r.section_type}\n\n${r.content}`).join('\n\n---\n\n');
}

async function handleRagSaveLearning({ agent_name, project, section_title, content, tags = [] }) {
  await query(
    `INSERT INTO rag_agent_instructions
       (agent_name, project, section_type, section_title, content, metadata)
     VALUES ($1, $2, 'learned-skill', $3, $4, $5::jsonb)`,
    [
      agent_name,
      project,
      section_title,
      content,
      JSON.stringify({
        tags,
        learned_at: new Date().toISOString(),
        source: 'mcp-rag-server',
      }),
    ]
  );
  return `✅ Learned skill saved: '${section_title}' → agent='${agent_name}', project='${project}'`;
}

async function handleRagAudit() {
  const rows = await query(
    `SELECT project, agent_name, COUNT(*) as sections,
            array_agg(DISTINCT section_type ORDER BY section_type) as types,
            MAX(created_at) as last_updated
     FROM rag_agent_instructions
     WHERE active = true
     GROUP BY project, agent_name
     ORDER BY project, sections DESC`
  );

  if (rows.length === 0) return 'No agents indexed in RAG.';

  return rows
    .map(
      (r) =>
        `${r.project} | ${r.agent_name} | ${r.sections} sections | ${r.types.join(', ')} | ${new Date(r.last_updated).toLocaleDateString()}`
    )
    .join('\n');
}

async function handleRagSearch({ keyword, project }) {
  const params = [`%${keyword}%`];
  let sql = `SELECT agent_name, project, section_type, section_title, LEFT(content, 200) as preview
             FROM rag_agent_instructions
             WHERE active = true AND content ILIKE $1`;
  if (project) {
    sql += ` AND project = $2`;
    params.push(project);
  }
  sql += ` ORDER BY agent_name, section_type LIMIT 10`;

  const rows = await query(sql, params);
  if (rows.length === 0) return `No results for '${keyword}'.`;

  return rows.map((r) => `[${r.project}] ${r.agent_name} / ${r.section_title}\n  ${r.preview}...`).join('\n\n');
}

// ── MCP request dispatcher ───────────────────────────────────────────────────

async function handleRequest(req) {
  const { id, method, params } = req;

  if (method === 'initialize') {
    return send({
      jsonrpc: '2.0',
      id,
      result: {
        protocolVersion: '2024-11-05',
        capabilities: { tools: {} },
        serverInfo: { name: 'rag-supabase', version: '1.0.0' },
      },
    });
  }

  if (method === 'tools/list') {
    return send({ jsonrpc: '2.0', id, result: { tools: TOOLS } });
  }

  if (method === 'tools/call') {
    const { name, arguments: args } = params;
    try {
      let result;
      if (name === 'rag_load') result = await handleRagLoad(args);
      else if (name === 'rag_save_learning') result = await handleRagSaveLearning(args);
      else if (name === 'rag_audit') result = await handleRagAudit();
      else if (name === 'rag_search') result = await handleRagSearch(args);
      else return error(id, -32601, `Unknown tool: ${name}`);

      return send({
        jsonrpc: '2.0',
        id,
        result: { content: [{ type: 'text', text: result }] },
      });
    } catch (e) {
      return error(id, -32000, e.message);
    }
  }

  // Ignore notifications (no id)
  if (id !== undefined) {
    error(id, -32601, `Method not found: ${method}`);
  }
}

// ── Main loop (stdio transport) ───────────────────────────────────────────────

const rl = readline.createInterface({ input: process.stdin });
rl.on('line', async (line) => {
  const trimmed = line.trim();
  if (!trimmed) return;
  try {
    const req = JSON.parse(trimmed);
    await handleRequest(req);
  } catch (e) {
    // Malformed JSON — ignore
  }
});
