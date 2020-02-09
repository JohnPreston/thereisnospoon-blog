.. title: EdgeOS and PIA - Isolate IOT and hide away the usual suspects
.. slug: edgeos-and-pia-isolate-iot-and-hide-away-the-usual-suspects
.. date: 2020-02-09 23:42:00 UTC
.. tags: EdgeOs, Vyatta, PIA, VPN
.. category: Networking, VPN
.. link:
.. description:
.. type: text

The why
=======

`#TLDR`_

I am a kid of the internet, Google, Wikipedia, Reddit, and all sites where people ask their questions and people from the community would come in and give a hand. And for that is the reason why I try to share back and help out. Especially my fellow AWS Architects, and even more so people who love CFN :D

There are already plenty of great videos by `CrossTalk Solutions`_ or `Willie Howe`_ about configuring the EdgeRouter OS (EdgeOS, for of `Vyatta`_) for OpenVpn Client which I can't recommend enough. These guys know networking to a point that I would simply look stupid, but I know a few things and the great thing is you can always reset and try again if you screw up.

I know that everything is looking at me, and I accepted that. I accept that Google can possibly read all my emails and ruin most of my life by leaking out my mails or go and reset my passwords etc. but that is somewhat part of our social contract with these SAS offerings. And the fact is, I even pay Google for some extra storage and other features.

On the other hand, my ISP, only provides me with internet access. And I absolutely do not want these guys to control and know my everymove.

I know, my ISP is nice to me and connects me to you readers. But for the money I pay and the service I get, I certainly do not feel generous to share any extra bit of information they can "anonymously" sell to others.

Think about it, you can clear your browser if you have kids that shouldn't know what you are watching at night, but your ISP always knows. So then you think, sure, let's make sure that everything runs over HTTPS, and you always should. Hence why even though this blog, raw text file, is published over SSL anyway.

So then you go to PIA or ExpressVPN, or crafty you go on LightSail or otherwise. So you mount your VPN, create your NAT (we will see all of that in a minute), and start routing your traffic through the VPN. Awesome.

But then, you have a problem: the more it goes, the more your favorite content media services such as Netflix think that you are using a VPN to access content in a different Geo Region. And they are probably right, a lot of people do that. We are not going to debate whether it is right or wrong, but, some people like me, only want to use a VPN to hide from their ISP what they are doing.

But then, you realize that there is one service above all that tells your ISP all the things you do, in clear text in your requests: DNS.

So what we are trying to do here today is:


* Dedicated VLAN where all the things route via the VPN (typically, I do that for all my IOT devices and then apply firewall rules to these).
* Route all DNS queries of your main LAN (where the TV, PC and otherwise connect to the internet).

.. _#TLDR:


The how
=======

Once the VPN is up and connected, We have a default GW provided by our ISP and then we have the one put in place by the VPN. My connection goes through VDSL, but the purpose of examples, I will be using the address 10.0.0.42/22 and my ISP default gateway obtained by DHCP as 10.0.0.1/22

For the next examples as well, we will have 2 VLANs:
* 100 for my home LAN on L3 192.168.0.0/24
* 107 for IoT on L3 192.168.1.0/25


I so then have different Firewall groups

.. code-block:: bash


   network-group INTERNAL {
     description INTERNAL
     network 192.168.0.0/24
     network 192.168.7.0/25
     }
   network-group IOT {
     description IOT
     network 192.168.7.0/25
     }
   network-group LAN-ALL {
     description "ALL LAN IPs"
     network 192.168.0.0/24
     }
   network-group LAN-PC {
     description LAN-PC
     network 192.168.0.0/25
     }
   network-group LAN-IOT {
     description LAN-IOT
     network 192.168.0.128/26
     }

These are going to be useful to use in human friendly configuration later on for our NATs etc.


Policy Based Routing (PBR)
--------------------------

Policy based routing is what is going to allow us to route traffic based on conditions. For example, in my topology, I have a very few IoT devices on the same broadcast domain as my PC and others, because for some functionality I had to have these in the same broadcast domain, but I wanted all traffic to be routed via the VPN anyway. Which is yet another variant of this configuration.

Routing tables
^^^^^^^^^^^^^^

Routing tables are useful to set specific routes via specific targets. So what we need is ensure that we have to different routing tables: 1 for the default GW of my ISP so I can play games etc with least latency and another one pointing to the tunnel interface. Sadly, you cannot use eth0 as the next hop-interface for your default route.

.. code-block:: bash

   protocols {
    static {
        table 1 {
            route 0.0.0.0/0 {
                next-hop 10.0.0.1 {
                }
            }
        }
        table 2 {
            interface-route 0.0.0.0/0 {
                next-hop-interface vtun0 {
                  }
              }
          }
      }
   }


Rule for internal traffic
^^^^^^^^^^^^^^^^^^^^^^^^^

First rule is pretty simple and simply indicates that all internal traffic should be internal.

.. code-block:: bash

   set firewall modify PBR rule 10 description "Internal routing"
   set firewall modify PBR rule 10 modify table main
   set firewall modify PBR rule 10 action modify
   set firewall modify PBR rule 10 source group network-group INTERNAL
   set firewall modify PBR rule 10 destination group network-group INTERNAL


.. code-block:: bash

   modify PBR {
     description "Main routing"
     enable-default-log
     rule 10 {
       action modify
       destination {
         group {
           network-group INTERNAL
         }
       }
       modify {
         table main
	 }
       source {
         group {
           network-group INTERNAL
           }
         }
     }


Rule to route LAN-PC traffic via the ISP GW
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

   set firewall modify PBR rule 20 description LAN-to-ISP
   set firewall modify PBR rule 20 action modify
   set firewall modify PBR rule 20 modify table 1
   set firewall modify PBR rule 20 source group network-group LAN-PC


Rule to route LAN-IOT traffic via the VPN
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

   set firewall modify PBR rule 21 description LAN-to-ISP
   set firewall modify PBR rule 21 action modify
   set firewall modify PBR rule 21 modify table 1
   set firewall modify PBR rule 21 source group network-group LAN-IOT



Rule to route traffic from IoT to VPN
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

   set firewall modify PBR rule 30 description IoT-to-VPN
   set firewall modify PBR rule 30 action modify
   set firewall modify PBR rule 30 modify table 2
   set firewall modify PBR rule 30 source group network-group IOT


Alternatively, you could use the network address range of your VLAN. Here, assuming the VLAN 107 for IOT is on port eth1

.. code-block:: bash

   set firewall modify PBR rule 30 source group address-group ADDRv4_eth1.107



Great. Our routes are in place but we have not defined any NATing as we still need to masquerade ourselves behind the router when getting out to the internet.

Setting up our NATs
^^^^^^^^^^^^^^^^^^^


.. code-block:: bash

   nat {
     rule 5000 {
       description IOT-to-PIA
       log disable
       outbound-interface vtun0
         protocol all
         source {
	   group {
             network-group IOT
	     }
           }
       type masquerade
     }
     rule 5001 {
       description LAN-IOT-to-PIA
       log disable
       outbound-interface vtun0
         protocol all
         source {
	   group {
             network-group LAN-IOT
	     }
           }
       type masquerade
     }
     rule 5002 {
       description LAN-PC-to-ISP
       log disable
       outbound-interface eth0
         protocol all
         source {
	   group {
             network-group LAN-PC
	     }
           }
       type masquerade
     }



.. code-block:: bash

   curl ifconfig.me


If you are connected to your IOT network, you should get the public IP address of your VPN.
If you are connected to the LAN-PC network and within 192.168.0.0/25 then you should get your ISP address (of course, the public IP, not 10.0.0.1) and if you are in the 192.168.0.128/25 range, you should also get the VPN public IP address.


Specifically re-route DNS via tunnel
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Well so very similarly as before, we are going to indicate to our router that we want the DNS traffic to be routed via our VPN. We don't need to do it for our IOT subnet, as all traffic goes through there anyway, but, we want to do that for all our hosts in the LAN (192.168.0.0/24) subnet.


.. code-block:: bash

   set firewall modify PBR rule 11 description DNS-to-VPN
   set firewall modify PBR rule 11 action modify
   set firewall modify PBR rule 11 modify table 2
   set firewall modify PBR rule 11 destination port 53
   set firewall modify PBR rule 11 protocol udp
   set firewall modify PBR rule 11 source group network-group LAN-ALL


Similarly to before, we need to get a NAT rule to get traffic through.

.. code-block:: bash

    rule 5003 {
            description DNS-TO-PIA
            destination {
                address 0.0.0.0/0
                port 53
            }
            log disable
            outbound-interface vtun0
            protocol udp
            source {
                group {
                    network-group LAN-ALL
                }
            }
            type masquerade
        }


How to check?
^^^^^^^^^^^^^

So how are we going to check that this works? I created a tiny EC2 instance on Amazon, setup bind with logging to file for all requests, and forward from there to CloudFlare etc.

Then from there you will be able to see what IP address the client used to make the DNS requests. If you see your ISP IP address, you forgot something along the lines to make sure that DNS requests are sent through.


.. note::

   Don't forget to change your DHCP server settings to point to some public DNS servers accordinly.


Do the same with Pi-Hole.
^^^^^^^^^^^^^^^^^^^^^^^^^

Pi-Hole is awesome and most of readers using Ubiquit probably also use Pi-Hole somewhere. If you setup your Pi-Hole in a different LAN etc (as I did), all you'd need to do is either route all traffic of your Pi-Hole server via VPN or apply the same rules as above to route the DNS requests of your server LAN to your VPN.


Conclusion
----------

So then, all the DNS requests are sent via the VPN. So even if you keep using your ISP connection for all your normal activities, at least, you aren't sending any DNS requests to anyone as yourself which would be the easiest thing for someone to figure out what you are accessing.

Maybe this feels like overkill to you, but I feel much better knowing that this is one less non TLS connection made through that doesn't come from my house specifically.


.. figure:: https://66.media.tumblr.com/tumblr_m6qacqt4X21qe6n4co1_400.gifv



.. _Crosstalk Solutions: https://www.youtube.com/channel/UCVS6ejD9NLZvjsvhcbiDzjw

.. _Willie Howe: https://www.youtube.com/channel/UCD-QkofF-bFBAcI83U8ZZeg

.. _Vyatta: https://www.vyos.io/


