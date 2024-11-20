def _vendors_manual_traefik_rule(domains):
    return " || ".join(
        f"Host(`{domain.strip()}`)" for domain in domains.strip().strip(",").split(",")
    )


def j2_environment(env):
    env.globals.update(
        generate_vendors_manual_traefik_rule=_vendors_manual_traefik_rule
    )
    return env
