When you have a manifest, some vars, and some automation in between.


# Intentions

    deployment/
      releases/
        dummy.json
      stemcells/
        default.json
      vars/
        bosh
        network.json
        creds
      manifest.jq

With the following `vars/bosh` you can reference release versions with `.bosh_release.{name}.version` and stemcell versions with `.bosh_stemcell.{name}.version`.

    #!/bin/sh

    set -e

    vars-scoped-dir bosh_release releases
    vars-scoped-dir bosh_stemcell stemcells

With the following `vars/creds` you can reference `.repo_key`, `.release_access_key`, and `.release_secret_access_key`.

    #!/bin/sh

    set -e

    vars-lpass \
      repo_key=123456789.notes \
      release_access_key_id=234567890.user \
      release_secret_access_key=234567890.password


# Utilities

With the following you can create a dev release, upload it to the director, and update the deployment release file.

    $ create-release ~/Projects/dpb587/dpb587.me/bosh/website-release aws-use1/website/deployment
