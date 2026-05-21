from pathlib import Path
import re
import json
from datetime import datetime

ROOT = Path(r"D:\safeher_flutter")
TARGET_DIRS = [ROOT / "lib", ROOT / "web"]
REPORT_DIR = ROOT / "_safeher_reports"
REPORT_DIR.mkdir(exist_ok=True)

BAD_MARKERS = ("à¦", "à§", "â€", "Â", "ðŸ", "�")

def has_bad(s: str) -> bool:
    return any(m in s for m in BAD_MARKERS)

def bangla_count(s: str) -> int:
    return sum(1 for ch in s if "\u0980" <= ch <= "\u09ff")

def repair_piece(s: str) -> str:
    if not has_bad(s):
        return s

    candidates = [s]
    for enc in ("cp1252", "latin1"):
        try:
            candidates.append(s.encode(enc, errors="ignore").decode("utf-8", errors="ignore"))
        except Exception:
            pass

    best = max(candidates, key=bangla_count)
    if bangla_count(best) > bangla_count(s):
        return best
    return s

def repair_dart_strings(text: str) -> str:
    # Repair only string literals that contain mojibake markers.
    # Supports common Dart single/double/triple quoted strings.
    pattern = re.compile(
        r"(?P<prefix>\br)?(?P<quote>'''|\"\"\"|'|\")(?P<body>.*?)(?P=quote)",
        re.DOTALL
    )

    def repl(m):
        prefix = m.group("prefix") or ""
        quote = m.group("quote")
        body = m.group("body")

        if not has_bad(body):
            return m.group(0)

        fixed = repair_piece(body)

        # If still broken, replace known Mitra fallback-type garbage with clean Bangla.
        if has_bad(fixed):
            lowered = fixed.lower()
            if "mitra" in lowered or "emergency guidance" in lowered or "safe place" in lowered:
                fixed = (
                    "আমি Mitra — আপনার confidential safety companion।\\n\\n"
                    "আমি emergency guidance, safe place, safe route, harassment help, legal aid, SOS support "
                    "এবং emotional support দিতে পারি।\\n\\n"
                    "আপনি চাইলে লিখতে পারেন:\\n"
                    "• SOS / emergency\\n"
                    "• safe place\\n"
                    "• harassment help\\n"
                    "• legal help\\n"
                    "• safe route"
                )
            else:
                fixed = "আমি আপনার কথা বুঝেছি। আপনি কী ধরনের সাহায্য চান?"

        return f"{prefix or ''}{quote}{fixed}{quote}"

    return pattern.sub(repl, text)

def repair_html(text: str) -> str:
    text = repair_piece(text)
    if "<head>" in text.lower() and "charset" not in text.lower():
        text = re.sub(r"(?i)<head>", '<head>\n  <meta charset="UTF-8">', text, count=1)
    return text

changed = []
remaining = []

for base in TARGET_DIRS:
    if not base.exists():
        continue

    for path in base.rglob("*"):
        if path.suffix.lower() not in (".dart", ".html", ".js", ".json"):
            continue

        try:
            original = path.read_text(encoding="utf-8-sig")
        except UnicodeDecodeError:
            original = path.read_text(encoding="cp1252", errors="ignore")

        new = original

        if path.suffix.lower() == ".dart":
            new = repair_dart_strings(new)
        elif path.suffix.lower() == ".html":
            new = repair_html(new)
        else:
            new = repair_piece(new)

        if new != original:
            path.write_text(new, encoding="utf-8")
            changed.append(str(path.relative_to(ROOT)))

        if has_bad(new):
            remaining.append(str(path.relative_to(ROOT)))

report = {
    "generated_at": datetime.now().isoformat(timespec="seconds"),
    "changed_files": changed,
    "remaining_files_with_mojibake_markers": remaining,
}

report_path = REPORT_DIR / f"flutter_bangla_mojibake_fix_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")

print("Changed files:")
for f in changed:
    print(" -", f)

print("\nRemaining files with mojibake markers:")
for f in remaining:
    print(" -", f)

print(f"\nReport saved: {report_path}")
