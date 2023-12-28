# its_my_party

## Summary
Sets up a new development environment for a Mac or Linux (i.e., UNIX) box.

**Table of Contents**
* [its\_my\_party](#its_my_party)
  * [Summary](#summary)
  * [Setup](#setup)
  * [Quickstart](#quickstart)
  * [Development](#development)
  * [TODO](#todo)
  * [Further Reading](#further-reading)

## Setup
* Minimum requirements
  * [Python 3.11](https://www.python.org/downloads/)
* Dev dependencies
  * make
    * [Linux](https://www.gnu.org/software/make/)
    * [macOS](https://www.freecodecamp.org/news/install-xcode-command-line-tools/)
  * [editorconfig](https://editorconfig.org/)
  * [wsl](https://docs.microsoft.com/en-us/windows/wsl/setup/environment)

## Quickstart
* Install python and tooling
    ```bash
    # install python and dependencies (e.g., git, ansible, etc.)
    ./bootstrap install
    ```
* Run server
    ```bash
    # script
    ./bootstrap run

    # manual
    gunicorn -w 4 -k uvicorn.workers.UvicornWorker -b 0.0.0.0:8000 app:app --reload
    ```

## Development
* `asdf`
    ```bash
    asdf install
    ```
* `poetry`
    ```bash
    # install dependencies
    poetry install

    # shell
    poetry shell

    # run
    poetry run python app.py

    # deactivate
    exit
    ```
* `./boostrap` commands
    ```bash
    # update pyproject.toml and poetry.lock
    ./bootstrap bump-deps

    # export requirements.txt
    ./bootstrap export-reqs

    # install git hooks
    ./bootstrap install-precommit

    # update git hooks
    ./bootstrap update-precommit
    ```
* [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/)
    ```bash
    # install commitizen
    npm install -g commitizen
    commitizen init cz-conventional-changelog --save-dev --save-exact

    # commit
    git add .

    # commitizen
    git cz
    ```

## TODO
* [Open Issues](https://github.com/pythoninthegrass/its_my_party/issues)
* Write boilerplate pytest tests
* CI/CD

## Further Reading
* [python](https://www.python.org/)
* [asdf](https://asdf-vm.com/guide/getting-started.html#_2-download-asdf)
* [poetry](https://python-poetry.org/docs/)
* [docker-compose](https://docs.docker.com/compose/install/)
* [pre-commit hooks](https://pre-commit.com/)
