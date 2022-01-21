#!/bin/bash
# -----------------------------------------------
# register a couple (host, vrf) in the radius database
# -----------------------------------------------

OUT_FILE=/tmp/create_host

helpFunction()
{
   echo ""
   echo "Usage: $0 -h hostname -n vrf_name -p password [-4 IPv4 prefix] [-6 IPv6 prefix]"
   echo -e "\t-h the name of the remote cpe"
   echo -e "\t-n the name of the VRF"
   echo -e "\t-p the CHAP password configured on the remote CPE"
   echo -e "\t-4 the IPv4 prefix for the remote CPE in CIDR natation (172.16.10.0/24)"
   echo -e "\t-6 the IPv6 prefix for the remote CPE"
   exit 1 # Exit script after printing help
}

while getopts "h:n:p:4:6:" opt
do
   case "$opt" in
      h ) cpe_name="$OPTARG" ;;
      n ) vrf_name="$OPTARG" ;;
      p ) cpe_password="$OPTARG" ;;
      4 ) ipv4_prefix="$OPTARG" ;;
      6 ) ipv6_prefix="$OPTARG" ;;
      ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done

# Print helpFunction in case parameters are empty
if [ -z "$cpe_name" ] || [ -z "$vrf_name" ] || [ -z "$cpe_password" ]
then
   echo "Some or all of the parameters are empty";
   helpFunction
fi

FullName="${cpe_name}@${vrf_name}.ark.local"
cat <<EOF > $OUT_FILE
/* Create a line per cpe in the PPP radcheck table */
INSERT INTO radcheck (username, attribute, op, value) VALUES (
  "${FullName}",   "Cleartext-Password",   ":=",  "${cpe_password}"
);
/* link to its VRF */
INSERT INTO radusergroup (username, groupname, priority) VALUES (
  "${FullName}", "${vrf_name}",  20
);
EOF

if [ ! -z "$ipv4_prefix" ]
then
   cat <<EOF >> $OUT_FILE
/* IPv4 routing */
INSERT INTO radreply (username, attribute, op, value) VALUES (
  "${FullName}",  "Framed-route",   "+=",  "${ipv4_prefix} 0.0.0.0 tag 4"
);
EOF
fi

if [ ! -z "$ipv6_prefix" ]
  then
        cat <<EOF >> $OUT_FILE
/* IPv6 routing */
INSERT INTO radreply (username, attribute, op, value) VALUES (
  "${FullName}",  "Framed-IPv6-route",   "+=",  "${ipv6_prefix} 0.0.0.0 tag 6"
);
EOF
fi

