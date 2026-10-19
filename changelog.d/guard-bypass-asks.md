- Guard: more of the ways around it now ask or deny instead of running. `scripts/guard.sh` asks before a shell reads
  its commands from a pipe, a here-string or a here-document, a command name built at run time (`$cmd push`), an
  `alias`, `xargs` starting a shell, a Python, Node or Ruby one-liner that starts another process, and a file the same
  command wrote and then runs. It asks before code that `curl` or `wget` fetches and a shell runs (`curl … | sh`,
  `sh -c "$(curl …)"`, `source <(curl …)`), also from an allowed host; before a package runner downloads a package that
  is not installed (`npx`, `bunx`, `pnpm dlx`, `uvx`, and `skills add`); before a `make`, package or script file named for a
  deploy, release or publish; before `ssh`; before `git reset --hard` and `git clean -f`; and before the file tools write
  outside the project and `/tmp`, a CI definition (`.github/workflows`), `.git/hooks` or `.git/config`. It denies a
  secret file name stored in a variable (`f=.env; cat $f`), a recursive `grep -r` or `rg --hidden` over a folder that
  holds a secret file unless it excludes it, and an environment branch in capitals (`git push origin Main`); `timeout`,
  `nice -n`, `stdbuf` and `sudo -u` no longer hide the command behind them, and `bash -lc '…'` is read like `bash -c`. A new
  `guard.installs` switch turns the package-runner asks off. `AGENTS.md` § Permissions for this project lists what is still
  not seen (a script file written in an earlier call, `npm install` of a named package, interpreter code that decodes
  itself, `WebFetch`).
