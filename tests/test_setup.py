"""Testes sem rede, sudo real ou alterações na pasta pessoal do usuário."""

import hashlib
import json
import os
from pathlib import Path
import shutil
import stat
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


class SetupTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name) / "home"
        self.home.mkdir()
        self.env = os.environ.copy()
        self.env.update(HOME=str(self.home), XDG_CONFIG_HOME=str(self.home / ".config"))
        self.env["GIT_CONFIG_GLOBAL"] = str(self.home / ".gitconfig")
        self.env["GIT_CONFIG_NOSYSTEM"] = "1"

    def run_setup(self, *args):
        return subprocess.run(
            ["bash", str(ROOT / "setup.sh"), *args],
            cwd=self.temp.name, env=self.env, text=True, capture_output=True,
        )

    def test_help_works_outside_repository(self):
        result = self.run_setup("--help")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("install", result.stdout)
        self.assertEqual(list(self.home.iterdir()), [])

    def test_all_dry_runs_are_read_only(self):
        # Falha se algum perfil tentar usar sudo ou rede no modo de simulação.
        fake_bin = Path(self.temp.name) / "bin"
        fake_bin.mkdir()
        for tool in ("sudo", "curl", "git", "apt-get"):
            executable = fake_bin / tool
            executable.write_text("#!/bin/sh\necho unexpected-command >&2\nexit 99\n")
            executable.chmod(0o755)
        self.env["PATH"] = f"{fake_bin}:{self.env['PATH']}"
        for profile in ("terminal", "node", "web", "mobile", "all"):
            with self.subTest(profile=profile):
                result = self.run_setup("install", profile, "--dry-run")
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertNotIn("unexpected-command", result.stderr)
                self.assertEqual(list(self.home.iterdir()), [])

    def test_invalid_arguments_fail_before_mutation(self):
        for args in (("install",), ("install", "invalid"), ("install", "web", "--force"), ("unknown",)):
            with self.subTest(args=args):
                self.assertNotEqual(self.run_setup(*args).returncode, 0)
                self.assertEqual(list(self.home.iterdir()), [])

    @unittest.skipIf(os.geteuid() == 0, "O comando de identidade exige usuário normal")
    def test_git_identity_is_configured_in_isolated_home(self):
        result = self.run_setup("git", "Sandro | DevAgress", "codigosecafe@gmail.com")
        self.assertEqual(result.returncode, 0, result.stderr)
        config = (self.home / ".gitconfig").read_text()
        self.assertIn("Sandro | DevAgress", config)
        self.assertIn("codigosecafe@gmail.com", config)

    @unittest.skipIf(os.geteuid() == 0, "O comando de identidade exige usuário normal")
    def test_ssh_key_has_no_passphrase_and_is_never_overwritten(self):
        result = self.run_setup("ssh", "Teste <teste@example.com>", "--no-passphrase")
        self.assertEqual(result.returncode, 0, result.stderr)
        key = self.home / ".ssh/id_ed25519"
        before = hashlib.sha256(key.read_bytes()).hexdigest()
        self.assertEqual(stat.S_IMODE(key.stat().st_mode), 0o600)
        self.assertEqual(stat.S_IMODE(key.parent.stat().st_mode), 0o700)
        derived = subprocess.run(
            ["ssh-keygen", "-y", "-P", "", "-f", str(key)],
            text=True, capture_output=True, check=True,
        ).stdout.split()[:2]
        self.assertEqual(derived, key.with_suffix(".pub").read_text().split()[:2])
        second = self.run_setup("ssh", "Outro comentário", "--no-passphrase")
        self.assertNotEqual(second.returncode, 0)
        self.assertEqual(before, hashlib.sha256(key.read_bytes()).hexdigest())
        self.assertNotIn("PRIVATE KEY", result.stdout)

    def test_environment_is_idempotent_in_bash_and_zsh(self):
        for shell in ("bash", "zsh"):
            if not shutil.which(shell):
                continue
            with self.subTest(shell=shell):
                result = subprocess.run(
                    [shell, "-c", '. "$1"; before="$PATH"; . "$1"; test "$before" = "$PATH"',
                     "test", str(ROOT / "config/env.sh")],
                    env=self.env, text=True, capture_output=True,
                )
                self.assertEqual(result.returncode, 0, result.stderr)

    def test_database_credentials_are_private_stable_and_scoped(self):
        self.env["CONFIG_DIR"] = str(self.home / ".config/script-up-server")
        self.env["SQL_LOG"] = str(Path(self.temp.name) / "sql.log")
        script = r'''
set -Eeuo pipefail
source "$1/lib/common.sh"
source "$1/modules/web.sh"
sudo() {
  [[ "$1" == mariadb ]] || return 99
  if [[ "${2:-}" == --batch ]]; then printf '0\n'; else cat >> "$SQL_LOG"; fi
}
mkdir -p "$CONFIG_DIR"
configure_database
cp "$CONFIG_DIR/mariadb.env" "$CONFIG_DIR/before.env"
configure_database
cmp "$CONFIG_DIR/before.env" "$CONFIG_DIR/mariadb.env"
'''
        result = subprocess.run(
            ["bash", "-c", script, "test", str(ROOT)], env=self.env,
            text=True, capture_output=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        credentials = Path(self.env["CONFIG_DIR"]) / "mariadb.env"
        self.assertEqual(stat.S_IMODE(credentials.stat().st_mode), 0o600)
        sql = Path(self.env["SQL_LOG"]).read_text()
        self.assertIn(r"ON `dev\_%`.*", sql)
        self.assertNotIn("ON *.*", sql)
        self.assertNotIn("GRANT OPTION", sql)
        self.assertNotIn("'root'", sql)

    def test_syntax_and_json(self):
        scripts = [ROOT / "setup.sh", ROOT / "config/env.sh"]
        scripts += list((ROOT / "lib").glob("*.sh"))
        scripts += list((ROOT / "modules").glob("*.sh"))
        for path in scripts:
            subprocess.run(["bash", "-n", str(path)], check=True, capture_output=True)
        if shutil.which("zsh"):
            subprocess.run(["zsh", "-n", str(ROOT / "config/terminal.zsh")], check=True)
        with (ROOT / "config/windows-terminal-dracula.json").open() as file:
            self.assertEqual(json.load(file)["name"], "Dracula")


if __name__ == "__main__":
    unittest.main()
