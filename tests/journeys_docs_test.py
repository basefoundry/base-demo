"""Keep short entry points and AI guidance aligned without pretending to run setup."""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]


class JourneyDocsTests(unittest.TestCase):
    def test_entry_points_precede_inventory(self):
        readme = (ROOT / "README.md").read_text()
        self.assertLess(readme.index("## Start with your goal"), readme.index("## Complete command reference"))
        guide = (ROOT / "docs/first-success.md").read_text()
        for title in ("Evaluate Base", "Adopt Base in a project", "Contribute to base-demo"):
            section = guide.split("## " + title + "\n", 1)[1].split("\n## ", 1)[0]
            for marker in ("**Prerequisite:", "**Done:", "**Safe failure/recovery:"):
                self.assertIn(marker, section)
        for page in ("adopter-golden-path", "first-run-troubleshooting", "json-output-quickstart",
                     "downstream-release-smoke-test"):
            self.assertIn(f"/docs/{page}.md", guide)
        for target in re.findall(r"\]\(([^)]+)\)", guide):
            if not target.startswith("https://"):
                self.assertTrue((ROOT / "docs" / target.split("#")[0]).exists(), target)

    def test_scope_and_health_marker_agree(self):
        overview = (ROOT / ".ai-context/overview.md").read_text()
        guide = (ROOT / "docs/first-success.md").read_text()
        self.assertNotIn("declares every current Base contract", overview)
        for text in (overview, guide):
            self.assertIn("curated representative subset", text)
            self.assertIn("BASE_DEMO_ENV", text)
            self.assertIn("baseline", text)
            self.assertIn("services --env dev", text)


if __name__ == "__main__":
    unittest.main()
