import re
import sys
from pathlib import Path

from setuptools import find_packages, setup

here = Path(sys.argv[0] if __name__ == "__main__" else __file__).resolve().parent


def read_reqs( reqs_path: Path):
    return re.findall(r'(^[^#-][\w]+[-~>=<.\w]+)', reqs_path.read_text(), re.MULTILINE)


#-----------------------------------------------------------------

install_requirements = read_reqs( here / "requirements" / "_base.txt" ) + [
    "simcore-service-library==0.1.0",
]
test_requirements = read_reqs( here / "requirements" / "_test.txt" )

setup(
    name='simcore-service-deployment-agent',
    version='0.9.2',
    description='Agent that automatically deploy services in a swarm',
    packages=find_packages(where='src'),
    package_dir={
        '': 'src',
    },
    include_package_data=True,
    package_data={
        '': [
            'config/*.y*ml',
            'oas3/v0/*.y*ml',
            'oas3/v0/components/schemas/*.y*ml',
            'data/*.json',
            'templates/**/*.html',
            ]
    },
    entry_points={
        'console_scripts': [
            'simcore-service-deployment-agent = simcore_service_deployment_agent.cli:main',
        ]
    },
    python_requires='>=3.6',
    install_requires=install_requirements,
    tests_require=test_requirements,
    setup_requires=['pytest-runner']
)
