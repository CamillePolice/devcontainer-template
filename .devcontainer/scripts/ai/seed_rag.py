#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
seed_rag.py — Indexation générique de fichiers Markdown/Python dans Supabase (pgvector).

Parse des fichiers Markdown ou Python, découpe leur contenu en sections sémantiques,
et les insère dans la table rag_agent_instructions de Supabase.

Usage :
    # Indexer un dossier complet pour un agent
    python seed_rag.py --dir . --agent archforge

    # Indexer un fichier spécifique
    python seed_rag.py --file angular-expert-rag.md --agent angular-expert

    # Dry-run pour prévisualiser sans toucher à la BDD
    python seed_rag.py --dir . --agent archforge --dry-run --preview

    # Réindexer en écrasant l'existant
    python seed_rag.py --dir . --agent archforge --force

Variables d'environnement :
    RAG_DSN      Connection string Supabase (requis sauf --dry-run)
    RAG_PROJECT  Nom du projet (ex: "archforge", "global") — défaut: "global"

Dépendances :
    pip install psycopg2-binary
"""

import argparse
import json
import os
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

try:
    import psycopg2
    from psycopg2.extras import execute_values
except ImportError:
    print("❌ psycopg2 requis : pip install psycopg2-binary", file=sys.stderr)
    sys.exit(1)


# ============================================================================
# Détection automatique du section_type à partir du titre
# ============================================================================

SECTION_TYPE_RULES: list[tuple[str, str]] = [
    # Rôle / présentation
    (r"^role$|rôle|vue\s+d.ensemble|objectif|présentation|overview|who\s+you\s+are", "role"),

    # Process / procédure
    (r"phase\s+\d|étape\s+\d|step\s+\d|phase\s+[a-z]|partie\s+[a-g]", "process"),
    (r"phase\s+0|initialisation|démarrage|setup", "process"),
    (r"phase\s+1|analyse|diagnostic|cadrage", "process"),
    (r"phase\s+2|stratégie|from.scratch|upgrade.in.place", "process"),
    (r"phase\s+3|planning|tâches|sprints|découpage", "process"),
    (r"phase\s+4|génération|livrables", "process"),
    (r"mode\s+dce|inventaire\s+documentaire|mode\s+code", "process"),
    (r"prompt\s+\d|itérat|workflow|process|methodology|méthodologie", "process"),
    (r"arbre\s+de\s+décision|question\s+\d|choix|migration\s+priority", "process"),
    (r"comment\s+utiliser|quand\s+utiliser|when\s+to\s+use", "process"),
    # SecureByDesign — STEP (process procédural du skill)
    (r"^step\s+\d|^étape\s+\d", "process"),
    (r"language\s+detection|criticality\s+tier|anti.hallucination", "process"),
    (r"conflict\s+resol|security\s+theater|exception\s+manag", "process"),

    # Best practices — contrôles SBD et patterns de sécurité
    (r"best[\s_]practic|bonnes?\s+pratiques?|règles?\s+transversales?|standards?", "best_practices"),
    (r"ai.rules|code\s+style|conventions?|guidelines?", "best_practices"),
    (r"testing\s+standard|test\s+organ|mock\s+pattern", "best_practices"),
    (r"logging|error\s+handling|gestion\s+d.erreur", "best_practices"),
    (r"prohibited|forbidden|what\s+not\s+to|ne\s+pas\s+utiliser", "best_practices"),
    (r"typescript.*native|native.*typescript|ramda", "best_practices"),
    # SecureByDesign — contrôles SBD individuels
    (r"^sbd-\d+|sbd\s+\d+", "best_practices"),
    (r"input\s+valid|output\s+encod|prompt\s+inject", "best_practices"),
    (r"authenticat|authoriz|least\s+privil", "best_practices"),
    (r"secrets?\s+manag|cryptograph|key\s+manag", "best_practices"),
    (r"data\s+minimiz|rate\s+limit|ssrf", "best_practices"),
    (r"depend.*scan|ci.cd\s+integ|supply\s+chain", "best_practices"),
    (r"llm\s+integr|rag\s+secur|system\s+prompt", "best_practices"),
    (r"network|cors|secure\s+design|governance", "best_practices"),
    (r"asset\s+inventor|incident\s+response|privacy", "best_practices"),
    (r"frontend\s+framework|angular.*secur|react.*secur|vue.*secur", "best_practices"),
    # SecureByDesign — LAYER groupings (H3 sous les 26 contrôles)
    (r"layer\s+\d|couche\s+\d", "best_practices"),

    # Edge cases
    (r"edge\s+case|cas\s+limite|fallback|mode\s+manuel|reprise|interruption", "edge_cases"),
    (r"breaking.changes|dépréciat|migration\s+note|gotcha|piège|problème", "edge_cases"),
    (r"common\s+diff|type\s+evolution|known\s+issue", "edge_cases"),
    # SecureByDesign — faux positifs et exceptions
    (r"false\s+positive|exception.*valid|acceptable.*deviation", "edge_cases"),
    (r"security\s+theater|decorative|bypass.*acceptable", "edge_cases"),

    # Output format — rapports et templates
    (r"output|sortie\s+attendue|livrables?|template\s+de\s+sortie|format\s+de\s+sortie", "output_format"),
    (r"résultat\s+attendu|exemple\s+de\s+sortie|checklist", "output_format"),
    # SecureByDesign — rapport d'audit et quick reference
    (r"audit\s+report|rapport\s+d.audit|quick\s+reference|red\s+flags?", "output_format"),
    (r"standards?\s+mapping|compliance\s+matrix|scope\s+of\s+assurance", "output_format"),

    # Reference — architecture, stack, standards
    (r"prérequis|installation|dépendances|outils|stack|technology", "reference"),
    (r"architecture|structure|infrastructure", "reference"),
    (r"scripts?|convert_|merge_|generate_", "reference"),
    (r"formats?\s+de\s+données|yaml|template|schéma", "reference"),
    (r"contribuer|licence|changelog|readme", "reference"),
    (r"guide\s+spécialisé|articulation|index|table\s+of\s+contents", "reference"),
    (r"scss|bootstrap|css|styling", "reference"),
    # SecureByDesign — standards et mappings
    (r"owasp|nist|iso.*27001|cis\s+control|gdpr|hipaa|ccpa|pci", "reference"),
    (r"version.*changelog|skill\s+v\d|released", "reference"),
]

DEFAULT_SECTION_TYPE = "reference"

# Fichiers toujours ignorés
IGNORE_FILES = {"seed_rag.py", "seed_archforge_rag.py", "README.md"}
IGNORE_DIRS  = {".git", "node_modules", "__pycache__", ".devcontainer", ".venv", "venv", ".claude"}

SEP = "─" * 60


# ============================================================================
# Structures de données
# ============================================================================

@dataclass
class RagSection:
    agent_name: str
    project: str
    section_type: str
    section_title: str
    content: str
    source_file: str
    metadata: dict = field(default_factory=dict)

    def char_count(self) -> int:
        return len(self.content)

    def is_valid(self) -> bool:
        """Section valide : contenu substantiel > 50 chars et au moins 2 lignes."""
        stripped = self.content.strip()
        if len(stripped) < 50:
            return False
        meaningful_lines = [
            l for l in stripped.splitlines()
            if l.strip() and not l.strip().startswith("```")
        ]
        return len(meaningful_lines) >= 2


# ============================================================================
# Parsing Markdown
# ============================================================================

def infer_section_type(title: str, default: str = DEFAULT_SECTION_TYPE) -> str:
    """Déduit le section_type à partir du titre de la section."""
    title_lower = title.lower()
    for pattern, stype in SECTION_TYPE_RULES:
        if re.search(pattern, title_lower):
            return stype
    return default


def strip_frontmatter(content: str) -> tuple[str, dict]:
    """Supprime le frontmatter YAML (--- ... ---) et retourne (content, meta)."""
    meta = {}
    if content.startswith("---"):
        end = content.find("---", 3)
        if end != -1:
            frontmatter = content[3:end].strip()
            for line in frontmatter.splitlines():
                if ":" in line:
                    k, _, v = line.partition(":")
                    meta[k.strip()] = v.strip()
            content = content[end + 3:].strip()
    return content, meta


def extract_doc_title(content: str) -> str:
    """Extrait le titre principal du document (premier # Titre)."""
    for line in content.splitlines():
        line = line.strip()
        if line.startswith("# "):
            return line[2:].strip()
    return ""


def split_into_sections(
    content: str,
    agent_name: str,
    project: str,
    source_file: str,
    default_section_type: str = DEFAULT_SECTION_TYPE,
) -> list[RagSection]:
    """
    Découpe le contenu Markdown en sections sémantiques.

    Stratégie :
    - Les titres H2 (##) créent des sections principales
    - Les H3 sont inclus dans la H2 parente sauf si section > MAX_CHARS
    - Le contenu avant le premier H2 devient une section "role"
    """
    MAX_CHARS = 4000

    content, _ = strip_frontmatter(content)
    doc_title = extract_doc_title(content)
    sections: list[RagSection] = []

    h2_pattern = re.compile(r"^#{2}\s+(.+)$", re.MULTILINE)
    h2_splits = list(h2_pattern.finditer(content))

    # Preamble avant le premier H2 → section "role"
    preamble = content[: h2_splits[0].start()].strip() if h2_splits else content.strip()
    if preamble and len(preamble) > 50:
        title = doc_title or f"{source_file} — Vue d'ensemble"
        sections.append(RagSection(
            agent_name=agent_name,
            project=project,
            section_type="role",
            section_title=title,
            content=preamble,
            source_file=source_file,
            metadata={"source_file": source_file, "heading_level": 1},
        ))

    # Sections H2
    for i, match in enumerate(h2_splits):
        section_title = match.group(1).strip()
        start = match.start()
        end = h2_splits[i + 1].start() if i + 1 < len(h2_splits) else len(content)
        section_content = content[start:end].strip()
        section_type = infer_section_type(section_title, default_section_type)

        if len(section_content) <= MAX_CHARS:
            sections.append(RagSection(
                agent_name=agent_name,
                project=project,
                section_type=section_type,
                section_title=section_title,
                content=section_content,
                source_file=source_file,
                metadata={"source_file": source_file, "heading_level": 2},
            ))
        else:
            # Section trop grande → découpage sur H3
            h3_pattern = re.compile(r"^#{3}\s+(.+)$", re.MULTILINE)
            h3_splits = list(h3_pattern.finditer(section_content))

            if not h3_splits:
                sections.append(RagSection(
                    agent_name=agent_name,
                    project=project,
                    section_type=section_type,
                    section_title=section_title,
                    content=section_content,
                    source_file=source_file,
                    metadata={"source_file": source_file, "heading_level": 2},
                ))
            else:
                # Contenu avant le premier H3
                h3_preamble = section_content[: h3_splits[0].start()].strip()
                if h3_preamble and len(h3_preamble) > 50:
                    sections.append(RagSection(
                        agent_name=agent_name,
                        project=project,
                        section_type=section_type,
                        section_title=f"{section_title} — Introduction",
                        content=h3_preamble,
                        source_file=source_file,
                        metadata={"source_file": source_file, "heading_level": 2},
                    ))

                # Sections H3
                for j, h3_match in enumerate(h3_splits):
                    h3_title = h3_match.group(1).strip()
                    h3_start = h3_match.start()
                    h3_end = h3_splits[j + 1].start() if j + 1 < len(h3_splits) else len(section_content)
                    h3_content = section_content[h3_start:h3_end].strip()
                    h3_type = infer_section_type(h3_title, section_type)

                    if len(h3_content) <= MAX_CHARS:
                        sections.append(RagSection(
                            agent_name=agent_name,
                            project=project,
                            section_type=h3_type,
                            section_title=f"{section_title} — {h3_title}",
                            content=h3_content,
                            source_file=source_file,
                            metadata={
                                "source_file": source_file,
                                "heading_level": 3,
                                "parent_section": section_title,
                            },
                        ))
                    else:
                        # H3 encore trop grande → découpage sur H4 (ex: contrôles SBD)
                        h4_pattern = re.compile(r"^#{4}\s+(.+)$", re.MULTILINE)
                        h4_splits = list(h4_pattern.finditer(h3_content))

                        if not h4_splits:
                            sections.append(RagSection(
                                agent_name=agent_name,
                                project=project,
                                section_type=h3_type,
                                section_title=f"{section_title} — {h3_title}",
                                content=h3_content,
                                source_file=source_file,
                                metadata={
                                    "source_file": source_file,
                                    "heading_level": 3,
                                    "parent_section": section_title,
                                },
                            ))
                        else:
                            for k, h4_match in enumerate(h4_splits):
                                h4_title = h4_match.group(1).strip()
                                h4_start = h4_match.start()
                                h4_end = h4_splits[k + 1].start() if k + 1 < len(h4_splits) else len(h3_content)
                                h4_content = h3_content[h4_start:h4_end].strip()
                                h4_type = infer_section_type(h4_title, h3_type)

                                sections.append(RagSection(
                                    agent_name=agent_name,
                                    project=project,
                                    section_type=h4_type,
                                    section_title=h4_title,
                                    content=h4_content,
                                    source_file=source_file,
                                    metadata={
                                        "source_file": source_file,
                                        "heading_level": 4,
                                        "parent_section": f"{section_title} — {h3_title}",
                                    },
                                ))

    return sections


def parse_markdown_file(filepath: Path, project: str, agent_name: str) -> list[RagSection]:
    """Parse un fichier Markdown en sections RAG."""
    try:
        content = filepath.read_text(encoding="utf-8")
    except Exception as e:
        print(f"  ❌ Erreur lecture {filepath.name}: {e}")
        return []

    sections = split_into_sections(
        content=content,
        agent_name=agent_name,
        project=project,
        source_file=filepath.name,
    )

    valid = [s for s in sections if s.is_valid()]
    skipped = len(sections) - len(valid)
    if skipped:
        print(f"  ⚠  {skipped} section(s) trop courtes ignorées")
    return valid


def parse_python_file(filepath: Path, project: str, agent_name: str) -> list[RagSection]:
    """Indexe un script Python comme une section reference unique."""
    try:
        content = filepath.read_text(encoding="utf-8")
    except Exception as e:
        print(f"  ❌ Erreur lecture {filepath.name}: {e}")
        return []

    # Extraire la docstring du module
    docstring = ""
    stripped = content.lstrip()
    for quote in ('"""', "'''"):
        if stripped.startswith(quote):
            end = stripped.find(quote, 3)
            if end != -1:
                docstring = stripped[3:end].strip()
            break

    section_title = f"Script : {filepath.name}"
    body = f"## {section_title}\n\n"
    if docstring:
        body += f"{docstring}\n\n"
    body += f"```python\n{content}\n```"

    section = RagSection(
        agent_name=agent_name,
        project=project,
        section_type="reference",
        section_title=section_title,
        content=body,
        source_file=filepath.name,
        metadata={"source_file": filepath.name, "file_type": "python"},
    )
    return [section] if section.is_valid() else []


# ============================================================================
# Découverte des fichiers
# ============================================================================

def discover_files(search_dir: Path, agent_name: str) -> list[tuple[Path, str]]:
    """
    Trouve récursivement tous les .md et .py dans le dossier.
    Retourne une liste de (filepath, agent_name).
    """
    found = []

    def is_ignored(path: Path) -> bool:
        if any(part in IGNORE_DIRS for part in path.parts):
            return True
        return path.name in IGNORE_FILES

    for md_file in sorted(search_dir.rglob("*.md")):
        if not is_ignored(md_file):
            found.append((md_file, agent_name))
            print(f"  📄 Trouvé : {md_file.relative_to(search_dir)}")

    for py_file in sorted(search_dir.rglob("*.py")):
        if not is_ignored(py_file):
            found.append((py_file, agent_name))
            print(f"  🐍 Trouvé : {py_file.relative_to(search_dir)}")

    return found


# ============================================================================
# Base de données
# ============================================================================

def get_connection(dsn: str):
    try:
        conn = psycopg2.connect(dsn)
        conn.autocommit = False
        return conn
    except Exception as e:
        print(f"❌ Connexion Supabase impossible : {e}", file=sys.stderr)
        sys.exit(1)


def table_exists(conn) -> bool:
    with conn.cursor() as cur:
        cur.execute("""
            SELECT EXISTS (
                SELECT FROM information_schema.tables
                WHERE table_name = 'rag_agent_instructions'
            );
        """)
        return cur.fetchone()[0]


def count_existing(conn, agent_name: str, project: str) -> int:
    with conn.cursor() as cur:
        cur.execute(
            "SELECT COUNT(*) FROM rag_agent_instructions "
            "WHERE agent_name = %s AND project = %s AND active = true",
            (agent_name, project),
        )
        return cur.fetchone()[0]


def delete_existing(conn, agent_name: str, project: str) -> tuple:
    """Désactive les sections existantes et retourne (total, répartition par type)."""
    with conn.cursor() as cur:
        cur.execute(
            "SELECT section_type, COUNT(*) FROM rag_agent_instructions "
            "WHERE agent_name = %s AND project = %s AND active = true "
            "GROUP BY section_type ORDER BY section_type",
            (agent_name, project),
        )
        by_type = {row[0]: row[1] for row in cur.fetchall()}
        cur.execute(
            "UPDATE rag_agent_instructions SET active = false "
            "WHERE agent_name = %s AND project = %s AND active = true",
            (agent_name, project),
        )
        return cur.rowcount, by_type



def insert_sections(conn, sections: list[RagSection]) -> int:
    if not sections:
        return 0
    rows = [
        (s.agent_name, s.project, s.section_type, s.section_title,
         s.content, json.dumps(s.metadata, ensure_ascii=False))
        for s in sections
    ]
    with conn.cursor() as cur:
        execute_values(
            cur,
            """
            INSERT INTO rag_agent_instructions
                (agent_name, project, section_type, section_title, content, metadata)
            VALUES %s
            """,
            rows,
            template="(%s, %s, %s, %s, %s, %s::jsonb)",
        )
    return len(rows)


# ============================================================================
# Affichage
# ============================================================================

def print_preview(sections: list[RagSection]) -> None:
    by_type: dict[str, list] = {}
    for s in sections:
        by_type.setdefault(s.section_type, []).append(s)

    for stype, slist in sorted(by_type.items()):
        print(f"\n  [{stype}] — {len(slist)} section(s)")
        for s in slist:
            print(f"    • {s.section_title[:70]:<70} ({s.char_count()} chars) [{s.source_file}]")


def print_report(sections: list[RagSection], inserted: int, deleted: int, deleted_by_type: dict, dry_run: bool) -> None:
    print()
    print(SEP)
    print("  RAPPORT D'INDEXATION → SUPABASE RAG")
    print(SEP)

    by_file: dict[str, list] = {}
    for s in sections:
        by_file.setdefault(s.source_file, []).append(s)

    print(f"\n{'Fichiers indexés':.<40} {len(by_file)}")
    for fname, slist in sorted(by_file.items()):
        total_chars = sum(s.char_count() for s in slist)
        print(f"  • {fname:<45} {len(slist):>3} sections  ({total_chars:>7} chars)")

    by_type: dict[str, int] = {}
    for s in sections:
        by_type[s.section_type] = by_type.get(s.section_type, 0) + 1

    print(f"\n{'Sections par type':.<40}")
    for stype, count in sorted(by_type.items()):
        print(f"  {stype:<30} {count:>4}")

    total_chars = sum(s.char_count() for s in sections)
    print(f"\n{'Total sections':.<40} {len(sections)}")
    print(f"{'Total caractères':.<40} {total_chars:,}")
    print(f"{'Taille moyenne':.<40} {total_chars // max(len(sections), 1):,} chars/section")

    print()
    print(SEP)
    if dry_run:
        print("  🔍 DRY RUN — Aucune modification en base")
    else:
        if deleted:
            print(f"  🗑  {deleted} section(s) précédentes désactivées :")
            for stype, count in sorted(deleted_by_type.items()):
                print(f"     - {stype:<30} {count:>4}")
        print(f"  ✅ {inserted} section(s) insérées dans Supabase")
    print(SEP)
    print()


# ============================================================================
# CLI
# ============================================================================

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Indexe des fichiers Markdown/Python dans Supabase (pgvector) pour architecture RAG-First.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Exemples :
  python seed_rag.py --dir . --agent archforge
  python seed_rag.py --file angular-expert-rag.md --agent angular-expert
  python seed_rag.py --files SKILL.md expert-rag.md --agent security-expert --force
  python seed_rag.py --file new-knowledge.md --agent security-expert --append
  python seed_rag.py --dir ./docs --agent mon-agent --dry-run --preview
  python seed_rag.py --dir . --agent archforge --force
        """,
    )
    parser.add_argument("--dir",   "-d", type=Path, help="Dossier à indexer récursivement")
    parser.add_argument("--file",  "-f", type=Path, help="Fichier unique à indexer")
    parser.add_argument("--files", "-F", type=Path, nargs="+", help="Plusieurs fichiers à indexer en une passe")
    parser.add_argument(
        "--agent", "-a", required=True,
        help="Nom de l'agent dans Supabase (ex: archforge, angular-expert)",
    )
    parser.add_argument(
        "--project", "-p",
        default=os.environ.get("RAG_PROJECT", "global"),
        help="Projet RAG (défaut: $RAG_PROJECT ou 'global')",
    )
    parser.add_argument("--dry-run",  action="store_true", help="Prévisualise sans écrire en base")
    parser.add_argument("--force",    action="store_true", help="Désactive tout l'agent puis réindexe")
    parser.add_argument("--append",   action="store_true", help="Ajoute sans toucher aux sections existantes")
    parser.add_argument("--preview",  action="store_true", help="Affiche le détail des sections parsées")
    return parser.parse_args()


# ============================================================================
# Main
# ============================================================================

def main() -> int:
    args = parse_args()

    if not args.dir and not args.file and not args.files:
        print("❌ Spécifier --dir, --file ou --files", file=sys.stderr)
        return 1

    if args.force and args.append:
        print("❌ --force et --append sont incompatibles", file=sys.stderr)
        return 1

    dsn = os.environ.get("RAG_DSN")
    if not dsn and not args.dry_run:
        print("❌ RAG_DSN non défini. Exporter la variable ou utiliser --dry-run", file=sys.stderr)
        return 1

    print()
    print(SEP)
    print("  SUPABASE RAG — Indexation")
    print(SEP)
    print(f"  Agent    : {args.agent}")
    print(f"  Projet   : {args.project}")
    print(f"  Mode     : {'DRY RUN' if args.dry_run else 'ÉCRITURE'}")
    if args.force:
        print("  ⚠  --force : toutes les sections existantes désactivées avant insertion")
    if args.append:
        print("  ➕ --append : ajout sans toucher aux sections existantes")
    print()

    # Découverte des fichiers
    files: list[tuple[Path, str]] = []

    if args.files:
        for f in args.files:
            files.append((f, args.agent))
    elif args.file:
        files.append((args.file, args.agent))
    else:
        print(f"🔍 Recherche dans : {args.dir}")
        files = discover_files(args.dir, args.agent)
        if not files:
            print("❌ Aucun fichier trouvé.")
            return 1

    print(f"\n📂 {len(files)} fichier(s) à traiter\n")

    # Parsing
    all_sections: list[RagSection] = []
    for filepath, agent_name in files:
        if filepath.suffix == ".py":
            print(f"🐍 Parsing : {filepath.name}")
            sections = parse_python_file(filepath, args.project, agent_name)
        else:
            print(f"📄 Parsing : {filepath.name}")
            sections = parse_markdown_file(filepath, args.project, agent_name)
        print(f"   → {len(sections)} sections extraites")
        all_sections.extend(sections)

    if not all_sections:
        print("\n❌ Aucune section valide extraite")
        return 1

    print(f"\n✅ Total : {len(all_sections)} sections valides extraites")

    if args.preview or args.dry_run:
        print("\n📋 Aperçu des sections :")
        print_preview(all_sections)

    if args.dry_run:
        print_report(all_sections, inserted=0, deleted=0, deleted_by_type={}, dry_run=True)
        return 0

    # Connexion Supabase
    print(f"\n🔌 Connexion à Supabase...")
    conn = get_connection(dsn)

    if not table_exists(conn):
        print("❌ Table 'rag_agent_instructions' introuvable.")
        conn.close()
        return 1

    # Vérification / suppression existant
    deleted = 0
    deleted_by_type: dict = {}
    existing = count_existing(conn, args.agent, args.project)
    if existing > 0:
        if args.force:
            print(f"🗑  Désactivation de {existing} sections existantes pour '{args.agent}' / '{args.project}'...")
            deleted, deleted_by_type = delete_existing(conn, args.agent, args.project)
        elif args.append:
            print(f"  ➕ {existing} sections existantes conservées — ajout par-dessus")
        else:
            print(f"\n⚠  {existing} sections existent déjà pour '{args.agent}' / projet '{args.project}'")
            print("   Utiliser --force pour tout réindexer, ou --append pour ajouter")
            conn.close()
            return 1

    # Insertion
    print(f"\n💾 Insertion de {len(all_sections)} sections...")
    try:
        inserted = insert_sections(conn, all_sections)
        conn.commit()
        print(f"   ✅ {inserted} sections insérées avec succès")
    except Exception as e:
        conn.rollback()
        print(f"   ❌ Erreur lors de l'insertion : {e}")
        conn.close()
        return 1

    # Vérification post-insertion
    print("\n📊 Vérification en base :")
    with conn.cursor() as cur:
        cur.execute("""
            SELECT section_type, COUNT(*) as n
            FROM rag_agent_instructions
            WHERE agent_name = %s AND project = %s AND active = true
            GROUP BY section_type ORDER BY n DESC;
        """, (args.agent, args.project))
        for stype, count in cur.fetchall():
            print(f"  {stype:<30} {count:>4} sections")

    conn.close()
    print_report(all_sections, inserted=inserted, deleted=deleted, deleted_by_type=deleted_by_type, dry_run=False)
    return 0


if __name__ == "__main__":
    sys.exit(main())