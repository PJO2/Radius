#!/bin/bash
# -----------------------------
# register a VRF into the Radius database
# -----------------------------

helpFunction()
{
   echo ""
   echo "Usage: $0 -n vrf_name -i vrfÃ_id"
   echo -e "\t-n the name of the VRF and POOls"
   echo -e "\t-i the id of the VRF and its loopback id"
   exit 1 # Exit script after printing help
}

while getopts "n:i:" opt
do
   case "$opt" in
      n ) vrf_name="$OPTARG" ;;
      i ) vrf_id="$OPTARG" ;;
      ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done

# Print helpFunction in case parameters are empty
if [ -z "$vrf_name" ] || [ -z "$vrf_id" ]
then
   echo "Some or all of the parameters are empty";
   helpFunction
fi

cat <<EOF > /tmp/create_vrf
/* --------------------------------------
     Configuration de la VRF $vrf_name
  --------------------------------------- */

INSERT INTO radgroupreply (groupname, attribute, op, value) VALUES (
     "${vrf_name}", "Cisco-Avpair", "+=", "ip:vrf-id=${vrf_name}"
);
/* IPv4 Loopback interface association */
INSERT INTO radgroupreply (groupname, attribute, op, value) VALUES (
    "${vrf_name}",  "Cisco-Avpair", "+=", "ip:ip-unnumbered=Loopback${vrf_id}"
);
/* IPv4 pool association */
INSERT INTO radgroupreply (groupname, attribute, op, value) VALUES (
    "${vrf_name}",  "Cisco-Avpair",  "+=",  "ip:addr-pool=POOL_${vrf_name}"
);
/* IPv6 Loopback interface association */
INSERT INTO radgroupreply (groupname, attribute, op, value) VALUES (
    "${vrf_name}",  "Cisco-Avpair",  "+=", "lcp:interface-config=ipv6 unnumbered Loopback${vrf_id}"
);
/* IPv6 pool association */
INSERT INTO radgroupreply (groupname, attribute, op, value) VALUES (
    "${vrf_name}",  "Cisco-Avpair",  "+=", "lcp:interface-config=peer default ipv6 pool POOL_${vrf_name}_IPv6"
);
/* Service Type */
INSERT INTO radgroupreply (groupname, attribute, op, value) VALUES (
        "${vrf_name}",  "Service-Type",  "=",  "Framed-User"
);
/* Type PPP */
INSERT INTO radgroupreply (groupname, attribute, op, value) VALUES (
        "${vrf_name}",  "Framed-Protocol",  "==",  "PPP"
);
/* Class 4 */
INSERT INTO radgroupreply (groupname, attribute, op, value) VALUES (
        "${vrf_name}",  "Class",  "=",  4
);

EOF


