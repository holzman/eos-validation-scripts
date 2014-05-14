#!/bin/bash


# Namespace comands: node ls, fs ls, ns compact, 
echo -n "-> ns status: " && eos -b ns | grep booted > /dev/null && echo " passed " || echo " failed"
echo -n "-> node list: " && eos -b node ls | grep online | grep 'on ' >/dev/null && echo " passed " || echo " failed"
echo -n "-> fs list: "  && eos -b fs ls | grep nodrain | grep online >/dev/null && echo " passed " || echo " failed"

# Verify automated deletions 
echo -n "-> lustre settings: " && eos -b attr ls /lustre/unmerged | grep sys.lru.expire.match >/dev/nulll && echo " passed " || echo " failed"

# Verify group ACLs and quotas 
echo -n "-> sysacl: " && eos -b attr ls /eos/uscms/store/user/lpcmuon | grep sys.acl=  >/dev/null && echo " passed " || echo " failed"
echo -n "-> quotals: " && eos -b quota ls /eos/uscms/store/user/lpcmuon | grep us_cms  >/dev/null && echo " passed " || echo " failed"

# Verify balancing
echo -n "-> spacebalancing: " && eos -b group ls | grep balancing >/dev/null  && echo " passed " || echo " failed"


# Verify quota on
echo -n "-> quotaon: " && eos -b space status default | grep quota | grep on > /dev/null  && echo " passed " || echo " failed"
