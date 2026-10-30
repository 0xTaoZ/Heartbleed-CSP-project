# attacker

A minimal Python 3 container for the Heartbleed (CVE-2014-0160) client that will
target the lab's own `vulnerable` and `patched` servers on the internal network.

For now this is only the Python environment. The exploit and the memory parser
are added later. The container does not get `shared/secrets.env`, so the flag has
to be recovered from leaked memory, not read directly.

Lab use only.
