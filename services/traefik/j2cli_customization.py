def _generate_domain_capture_all_rule(domain: str) -> str:
    rules = [
        f"Host(`{domain}`)",
        f"Host(`www.{domain}`)",
        f"Host(`invitations.{domain}`)",
        f"Host(`services.{domain}`)",
        f"HostRegexp(`{{subhost:[a-zA-Z0-9-]+}}.services.{domain}`)",
        f"Host(`services.testing.{domain}`)",
        f"HostRegexp(`{{subhost:[a-zA-Z0-9-]+}}.services.testing.{domain}`)",
        f"Host(`pay.{domain}`)",
        f"Host(`api.{domain}`)",
        f"Host(`api.testing.{domain}`)",
        f"Host(`testing.{domain}`)",
    ]
    return " || ".join(rules)


def j2_environment(env):
    env.globals.update(
        generate_domain_capture_all_rule=_generate_domain_capture_all_rule,
        zip=zip,
    )
    return env
