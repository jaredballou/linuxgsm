#!/usr/bin/env python
import hiyapyco
import sys, os
import yaml
import json
from pprint import pprint as pp
import datetime
try:
    from collections import OrderedDict
except ImportError:
    # try importing the backported replacement
    # requires a: `pip-2.6 install ordereddict`
    from ordereddict import OrderedDict

def dict_merge(dct, merge_dct):
    """ Recursive dict merge. Inspired by :meth:``dict.update()``, instead of
    updating only top-level keys, dict_merge recurses down into dicts nested
    to an arbitrary depth, updating keys. The ``merge_dct`` is merged into
    ``dct``.
    :param dct: dict onto which the merge is executed
    :param merge_dct: dct merged into dct
    :return: None
    """
    for k, v in merge_dct.iteritems():
        if (k in dct and isinstance(dct[k], dict)
                and isinstance(merge_dct[k], dict)):
            dict_merge(dct[k], merge_dct[k])
        else:
            dct[k] = merge_dct[k]

def load_gamedata_file(file):
    bn = os.path.basename(file).split('.')[0]
    conf = hiyapyco.load("gamedata/" + file, method=hiyapyco.METHOD_MERGE, interpolate=True, failonmissingfiles=True)
    data = OrderedDict()
    if (len(conf.keys()) == 1) and (conf.keys()[0] == bn):
        conf = conf[conf.keys()[0]]
    dict_merge(data,conf)
    if ("import" in data.keys()):
        for impfile in data["import"]:
            impfile = "%s.yaml" %(impfile)
            impdata = load_gamedata_file(impfile)
            dict_merge(impdata,data)
            dict_merge(data,impdata)
    if not ("config" in data.keys()):
        data["config"] = dict()
    # this is me doing something stupid so I can interpolate the config
    if ("settings" in data.keys()):
        for setting in data["settings"].keys():
            if "value" in data["settings"][setting].keys():
                data["config"][setting] = data["settings"][setting]["value"]
            else:
                data["config"][setting] = ""
    return data

def getval(dict,key):
    if not "settings" in dict.keys():
        return
    if not key in dict["config"].keys():
        return
#    pp(key)
#    pp(dict["config"][key])
    try:
        interp = dict["config"][key] % dict["config"]
    except:
        interp = dict["config"][key]
    return interp




conf = load_gamedata_file('games/insserver.yaml')

today = datetime.datetime.today()
config = {
    "date": today.strftime("%d-%m-%Y-%H-%M-%S"),
    "version": "090316",
    "core_script": "new.py",
    "scriptpath": os.path.realpath(__file__),
    "selfname": os.path.basename(os.path.realpath(__file__)),
    "servicename": os.path.basename(__file__),
    "rootdir": os.path.dirname(os.path.realpath(__file__)),
    "githubuser": "jaredballou",
    "githubrepo": "linuxgsm",
    "githubbranch": "python",
    "git_update": False,
    "lgsmdir": "%(rootdir)s/lgsm",
    "lgsmserverdir": "%(lgsmdir)s/servers/%(selfname)s",
    "logdir": "%(lgsmdir)s/servers/%(selfname)s/log",
    "parserdir": "%(lgsmserverdir)s/tmp",
    "gamedatadir": "%(lgsmdir)s/gamedata",
    "scriptcfgdir": "%(lgsmserverdir)s/cfg",
    "cachedir": "%(lgsmdir)s/tmp",
}

#conf["config"]["servicename"] = u"insserver"
#dict_merge(conf["config"],config)
#dict_merge(conf["config"],hiyapyco.load("tests/configs/_default.yaml", "tests/configs/_common.yaml", "tests/configs/" + conf["config"]["servicename"] + ".yaml", method=hiyapyco.METHOD_MERGE, interpolate=True, failonmissingfiles=True))
#for key in conf["config"].keys():
#    print "%s: %s" % (key,getval(conf,key))





#print json.dumps(conf, indent=4,sort_keys=True)
#print yaml.dump(
#pp(json.loads(json.dumps(conf)))
#pp(conf["config"])
#, default_flow_style=True)
#, Dumper=yaml.order.OrderedDumper, default_flow_style=False)
