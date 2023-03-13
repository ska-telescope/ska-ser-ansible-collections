#!/usr/bin/python

import string


class FilterModule(object):
    """Extract Mons filter"""

    def filters(self):
        return {
            "cephmons": self.cephmons,
            "cephmonsdata": self.cephmonsdata,
            "cephmonitors": self.cephmonitors,
        }

    def cephmons(self, mons):
        """
        cephmons filter
        integrate by adding FQ filter eg:
        {{ x | ska_collections.k8s.cephmons }}
        """
        # OLD FORMAT:!!!
        # "[v2:192.168.99.48:3300,v1:192.168.99.48:6789],[v2:192.168.99.197:3300,v1:192.168.99.197:6789],[v2:192.168.99.200:3300,v1:192.168.99.200:6789]"
        # NEW  FORMAT !!!
        # mon_host = [v2:10.165.4.17:3300/0,v1:10.165.4.17:6789/0] [v2:10.165.4.18:3300/0,v1:10.165.4.18:6789/0] [v2:10.165.4.19:3300/0,v1:10.165.4.19:6789/0] # noqa: 501
        # split and return nested array of dicts of ep version of dicts of the endpoints  # noqa: E501
        # "capi_capo_ceph_conf_global_mon_host": [
        #     {
        #         "v1": {
        #             "addr": "192.168.99.48",
        #             "endpoint": "192.168.99.48:6789",
        #             "port": "6789",
        #             "verion": "v1"
        #         },
        #         "v2": {
        #             "addr": "192.168.99.48",
        #             "endpoint": "192.168.99.48:3300",
        #             "port": "3300",
        #             "verion": "v2"
        #         }
        #     },
        #     ...
        # ]
        # tel black to ignore this as it does not wrap correctly
        # fmt: off
        spliter = "] "
        if "],[" in mons:
            spliter = "],"
        mons = [
            x.replace("[", "").replace("]", "").replace("/0", "").split(",")
            for x in mons.split(spliter)
        ]
        # fmt: on
        monitors = []
        for mon in mons:
            endpoints = {}
            for ep in mon:
                v, addr, port = ep.split(":")
                endpoints[v] = {
                    "verion": v,
                    "addr": addr,
                    "port": port,
                    "endpoint": addr + ":" + port,
                }
            monitors.append(endpoints)
        return monitors

    def cephmonsdata(self, mons):
        """
        cephmonsdata filter
        integrate by adding FQ filter eg:
        {{ x | ska_collections.k8s.cephmonsdata }}
        """
        # ROOK_EXTERNAL_CEPH_MON_DATA=a=192.168.99.48:3300,b=192.168.99.197:3300,c=192.168.99.200:3300

        letters = list(string.ascii_lowercase)

        mons = [mon["v2"] for mon in self.cephmons(mons) if "v2" in mon]
        monitors = []
        for mon in mons:
            monitors.append(letters.pop(0) + "=" + mon["endpoint"])
        return ",".join(monitors)

    def cephmonitors(self, mons):
        """
        cephmonitors filter
        integrate by adding FQ filter eg:
        {{ x | ska_collections.k8s.cephmonitors }}
        """
        # ROOK_EXTERNAL_CEPH_MONITORS="192.168.99.48:6789","192.168.99.197:6789","192.168.99.200:6789"

        monitors = [
            "QTE" + mon["v1"]["endpoint"] + "QTE"
            for mon in self.cephmons(mons)
            if "v1" in mon
        ]
        return ",".join(monitors)
