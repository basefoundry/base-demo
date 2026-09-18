"""Exercise the IDE consent guard with all mutation delegates replaced by spies."""
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import Mock, patch

from base_cli_adapters.config import UserConfig, UserIdeConfig
from base_setup.errors import ArtifactError
from base_setup.manifest import BaseManifest, IdeConfig
from base_setup import setup_reconcile


def main():
    context = SimpleNamespace(log=Mock(), yes=True,
                              user_config=UserConfig(raw={}, ide=UserIdeConfig(enabled=None, preferences={})))
    defaults = BaseManifest(path=Path("defaults.yaml"), project_name="defaults", brewfile=None, artifacts=())
    project = BaseManifest(path=Path("project.yaml"), project_name="fixture", brewfile=None, artifacts=(),
                           ide={"vscode": IdeConfig(install=False, extensions=(), settings={"editor.formatOnSave": True})})
    names = ("reconcile_brewfile", "reconcile_mise", "reconcile_ide_installs", "reconcile_ide_extensions",
             "reconcile_ide_settings", "reconcile_uv_project", "reconcile_artifacts")
    delegates = {name: Mock() for name in names}
    with patch.multiple(setup_reconcile, **delegates):
        try:
            setup_reconcile.reconcile_manifest(context, defaults, project, dry_run=False)
        except ArtifactError as error:
            assert "--allow-project-ide-mutations" in str(error)
            assert "--yes" in str(error)
        else:
            raise AssertionError("IDE mutation was not denied")
        assert not any(spy.called for spy in delegates.values())
        setup_reconcile.reconcile_manifest(context, defaults, project, dry_run=True)
        assert delegates["reconcile_ide_settings"].call_args.kwargs["dry_run"] is True
    print("PASS: IDE mutation guard denies without its own consent; preview delegates are dry-run only")


if __name__ == "__main__":
    main()
