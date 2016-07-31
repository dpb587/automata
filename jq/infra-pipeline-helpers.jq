def lock($name):
  {
    "put": ($name + "-lock"),
    "params": {
      "acquire": true
    }
  }
;

def unlock($name):
  {
    "put": ($name + "-lock"),
    "params": {
      "release": ($name + "-lock")
    }
  }
;

def wrap_with_locks($locks):
  (if $locks|type == "string" then [$locks] else $locks end) as $locks |
  true
;

def automata_rally_manifest($path):
  {
    "task": "generate-manifest",
    "file": "repository/ci/automata/tasks/rally/manifest/config.yml",
    "params": {
      "manifest": $path
    }
  }
;

def upload_release($release):
  {
    "name": ("upload-" + $release + "-release"),
    "serial": true,
    "plan": [
      {
        "aggregate": [
          {
            "get": "release",
            "resource": ($release + "-release"),
            "trigger": true
          },
          {
            "get": "repository"
          }
        ]
      },
      lock("bosh"),
      {
        "do": [
          {
            "task": "upload",
            "file": "repository/ci/automata/tasks/bosh/upload-release/config.yml",
            "params": {
              "target": .bosh_target,
              "ca_cert": .bosh_ca_cert,
              "username": .bosh_username,
              "password": .bosh_password
            }
          }
        ],
        "ensure": unlock("bosh")
      }
    ]
  }
;

def deployment($zone; $deployment; $component):
  {
    "name": ("update-" + $deployment + "-" + $component),
    "serial": true,
    "plan": [
      {
        "aggregate": [
          {
            "get": ($deployment + "-repo"),
            "trigger": true,
            "passed": [
              "update-" + $deployment + "-stack"
            ]
          },
          {
            "get": "repository",
          }
        ]
      },
      automata_rally_manifest($zone + "/" + $deployment + "/" + $component + "/manifest.jq"),
      lock($deployment),
      {
        "do": [
          {
            "put": ($deployment + "-" + $component),
            "params": {
              "manifest": "manifest/manifest.json",
              "stemcells": [],
              "releases": []
            }
          }
        ],
        "ensure": unlock($deployment)
      }
    ]
  }
;

def stack($zone; $deployment; $component; $options):
  {
    "name": ("update-" + $deployment + "-" + $component),
    "serial": true,
    "plan": [
      {
        "aggregate": [
          {
            "get": ($deployment + "-repo"),
            "trigger": true
          },
          {
            "get": "repository"
          }
        ]
      },
      automata_rally_manifest($zone + "/" + $deployment + "/" + $component + "/template.jq"),
      lock($deployment),
      {
        "do": [
          {
            "put": ($deployment + "-" + $component),
            "params": (
              {
                "template": "manifest/manifest.json"
              }
              + if $options | has("capabilities") then { "capabilities": $options.capabilities } else {} end
            )
          },
          {
            "task": "archive-stack",
            "file": "repository/ci/automata/tasks/aws-cloudformation-stack/archive-state/config.yml",
            "input_mapping": {
              "stack": ($deployment + "-stack")
            },
            "params": {
              "state": ($zone + "/" + $deployment + "/" + $component + "/state")
            }
          },
          {
            "put": "repository",
            "params": {
              "repository": "repository",
              "rebase": true
            }
          }
        ],
        "ensure": unlock($deployment)
      }
    ]
  }
;

def rally_releases($releases):
  . as $dot |
  $releases | map(select(.params)) | {
    "jobs": (map(
      {
        "name": ("upload-" + .name + "-" + .params.channel.name + "-release"),
        "serial": true,
        "plan": [
          {
            "aggregate": [
              {
                "get": "release",
                "resource": (.name + "-" + .params.channel.name + "-release"),
                "trigger": true
              },
              {
                "get": "repository"
              }
            ]
          },
          lock("bosh"),
          {
            "do": [
              {
                "task": "upload",
                "file": "repository/ci/automata/tasks/bosh/upload-release/config.yml",
                "params": {
                  "target": ($dot.bosh_target),
                  "ca_cert": ($dot.bosh_ca_cert),
                  "username": ($dot.bosh_username),
                  "password": ($dot.bosh_password)
                }
              }
            ],
            "ensure": unlock("bosh")
          }
        ]
      },
      {
        "name": ("bump-" + ._name),
        "serial": true,
        "plan": [
          {
            "aggregate": [
              {
                "get": "release",
                "resource": (.name + "-" + .params.channel.name + "-release"),
                "trigger": true,
                "passed": [
                  "upload-" + .name + "-" + .params.channel.name + "-release"
                ],
                "params": {
                  "tarball": false
                }
              },
              {
                "get": "repository"
              }
            ]
          },
          {
            "task": "bump",
            "file": "repository/ci/automata/tasks/rally/write-release/config.yml",
            "params": {
              "config": ._path,
              "commit_prefix": (._path | split("/")[1])
            }
          },
          {
            "put": "repository",
            "params": {
              "repository": "repository",
              "rebase": true
            }
          }
        ]
      }
    )),
    "resources": (map(
      {
        "name": (.name + "-" + .params.channel.name + "-release"),
        "type": "bosh-io-release",
        "source": {
          "repository": .repository,
          "server": .params.channel.url
        }
      }
    ))
  }
;

def rally_stemcells($stemcells):
  . as $dot |
  $stemcells | map(select(.params)) | {
    "jobs": (map(
      {
        "name": ("upload-" + .name + "-" + .params.channel.name + "-stemcell"),
        "serial": true,
        "plan": [
          {
            "aggregate": [
              {
                "get": "stemcell",
                "resource": (.name + "-" + .params.channel.name + "-stemcell"),
                "trigger": true
              },
              {
                "get": "repository"
              }
            ]
          },
          lock("bosh"),
          {
            "do": [
              {
                "task": "upload",
                "file": "repository/ci/automata/tasks/bosh/upload-stemcell/config.yml",
                "params": {
                  "target": ($dot.bosh_target),
                  "ca_cert": ($dot.bosh_ca_cert),
                  "username": ($dot.bosh_username),
                  "password": ($dot.bosh_password)
                }
              }
            ],
            "ensure": unlock("bosh")
          }
        ]
      },
      {
        "name": ("bump-" + ._name),
        "serial": true,
        "plan": [
          {
            "aggregate": [
              {
                "get": "stemcell",
                "resource": (.name + "-" + .params.channel.name + "-stemcell"),
                "trigger": true,
                "passed": [
                  "upload-" + .name + "-" + .params.channel.name + "-stemcell"
                ],
                "params": {
                  "tarball": false
                }
              },
              {
                "get": "repository"
              }
            ]
          },
          {
            "task": "bump",
            "file": "repository/ci/automata/tasks/rally/write-stemcell/config.yml",
            "params": {
              "config": ._path,
              "commit_prefix": (._path | split("/")[1])
            }
          },
          {
            "put": "repository",
            "params": {
              "repository": "repository",
              "rebase": true
            }
          }
        ]
      }
    )),
    "resources": (map(
      {
        "name": (.name + "-" + .params.channel.name + "-stemcell"),
        "type": "bosh-io-stemcell",
        "source": {
          "name": .name,
          "server": .params.channel.url
        }
      }
    ))
  }
;
