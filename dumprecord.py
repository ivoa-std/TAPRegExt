# Create a sample record using the GAVO DaCHS software.  Don't bother
# doing this unless you're Markus or you know you want to do it.

import subprocess

from gavo import api
from gavo.registry import capabilities

capabilities._TMP_TAPREGEXT_HACK = True

service = api.getRD("//tap").getById("run")
p = subprocess.Popen("xmlstarlet fo".split(), stdin=subprocess.PIPE)
p.stdin.write(
	capabilities.getCapabilityElement(service.publications[0]).render())
p.stdin.close()
