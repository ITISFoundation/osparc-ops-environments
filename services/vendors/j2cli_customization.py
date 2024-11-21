def _generate_vendors_manual_traefik_rule(domains: str, subdomain_prefix: str) -> str:
    domain_list = domains.strip().strip(",").split(",")
    domains = [f"{subdomain_prefix}.{domain}" for domain in domain_list]
    return " || ".join(domains)


def j2_environment(env):
    env.globals.update(
        generate_vendors_manual_traefik_rule=_generate_vendors_manual_traefik_rule
    )
    return env
