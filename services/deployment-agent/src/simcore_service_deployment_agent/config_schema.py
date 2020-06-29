import trafaret as T
from .rest_config import schema as rest_schema

app_schema = T.Dict({
    T.Key("host", default="0.0.0.0"): T.IP,
    "port": T.Int(),
    "log_level": T.Enum("DEBUG", "WARNING", "INFO", "ERROR", "CRITICAL", "FATAL", "NOTSET"),
    "watched_git_repositories": T.List(T.Dict({
        "id": T.String(),
        "url": T.URL,
        T.Key("username", optional=True, default=""): T.String(allow_blank=True),
        T.Key("password", optional=True, default=""): T.String(allow_blank=True),
        T.Key("branch", default="master", optional=True): T.String(allow_blank=True),
        T.Key("tags", default="", optional=True): T.String(allow_blank=True),
        "pull_only_files": T.Bool(),
        "paths": T.List(T.String()),
    }), min_length=1),
    "docker_private_registries": T.List(T.Dict({
        "url": T.URL,
        T.Key("username", optional=True, default=""): T.String(allow_blank=True),
        T.Key("password", optional=True, default=""): T.String(allow_blank=True)
    })),
    "docker_stack_recipe": T.Dict({
        "files": T.List(T.Dict({
            "id": T.String(),
            "paths": T.List(T.String()),
        })),
        "workdir": T.String(),
        "command": T.String(allow_blank=True),
        "stack_file": T.String(),
        "excluded_services": T.List(T.String()),
        "excluded_volumes": T.List(T.String()),
        "additional_parameters": T.Any(),
        T.Key("services_prefix", default="", optional=True): T.String(allow_blank=True)
    }),
    "portainer": T.List(T.Dict({
        "url": T.String(),
        T.Key("endpoint_id", optional=True, default=-1): T.Int(),
        T.Key("username", optional=True, default=""): T.String(allow_blank=True),
        T.Key("password", optional=True, default=""): T.String(allow_blank=True),
        "stack_name": T.String(),
    }), min_length=1),
    "polling_interval": T.Int(gte=0),
    "notifications": T.List(T.Dict({
            "service":T.String,
            "url": T.URL,
            "enabled": T.Bool(),
            "channel_id": T.String(),
            "personal_token": T.String(),
            "message": T.String(),
            "header_unique_name": T.String()
    }))
})

schema = T.Dict({
    "version": T.String(),
    T.Key("rest"): rest_schema,
    T.Key("main"): app_schema
})

# TODO: config submodule that knows about schema with web.Application intpu parameters
# TODO: def get_main_config(app: ):
