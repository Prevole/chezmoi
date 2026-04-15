GIT_URLS = {
    "emu": "git@github.com"
}

GIT_ORGS = {
    "REDACTED": "emu",
    "REDACTED-infra": "emu",
    "REDACTED-archives": "emu",
}

class FilterModule(object):
    def filters(self):
        return dict(
            git_url=self.git_url,
        )

    def git_url(self, org_repo: str) -> str:
        if org_repo.startswith("git@") or org_repo.startswith("http"):
            return org_repo

        org, repo, *_ = org_repo.replace(".git", "").split("/") + [None]

        if repo is not None and org in GIT_ORGS:
            return f'{GIT_URLS[GIT_ORGS[org]]}:{org_repo}.git'

        else:
            return f'{GIT_URLS["emu"]}:{org_repo}.git'
