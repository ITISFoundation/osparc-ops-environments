class AutoDeployAgentException(Exception):
    """Basic exception"""

    def __init__(self, msg=None):
        if msg is None:
            msg = "Unexpected error was triggered"
        super(AutoDeployAgentException, self).__init__(msg)


class NoErrorException(AutoDeployAgentException):
    """No error while checking for changes"""

    def __init__(self):
        msg = "no error, no problem"
        super(NoErrorException, self).__init__(msg)


class CmdLineError(AutoDeployAgentException):
    """Error while executing command line"""

    def __init__(self, cmd, error_msg):
        msg = "Error while executing {cmd}:\n{error_msg}".format(
            cmd=cmd, error_msg=error_msg)
        super(CmdLineError, self).__init__(msg)
        self.cmd = cmd
        self.error_msg = error_msg


class ConfigurationError(AutoDeployAgentException):
    """Wrong configuration error"""

    def __init__(self, msg):
        super(ConfigurationError, self).__init__(msg)


class DependencyNotReadyError(AutoDeployAgentException):
    """Dependency not ready error"""

    def __init__(self, msg):
        super(DependencyNotReadyError, self).__init__(msg)
