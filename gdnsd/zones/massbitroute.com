$TTL 300
$ORIGIN massbitroute.com.


@               SOA ns1.massbitroute.com. hostmaster.massbitroute.com.(
                2020072800  ; serial
                300            ; refresh
                30M             ; retry
                1D              ; expire
                300             ; ncache
)

; Name servers

@               NS      ns1.massbitroute.com.
@               NS      ns2.massbitroute.com.

; Wildcard services
;@		DYNA	geoip!generic-resource
;*		DYNA	geoip!generic-resource


hostmaster A 34.126.176.201
ns1 A 34.126.176.201
ns2 A 34.126.181.168

_acme-challenge CNAME 65aa0733-71fd-4efc-8f07-38ef32788059.auth.acme-dns.io.

@ A 34.126.176.201
* A 34.126.176.201
@ 3600 IN MX 5 gmr-smtp-in.l.google.com.
@ 3600 IN MX 10 alt1.gmr-smtp-in.l.google.com.
@ 3600 IN MX 20 alt2.gmr-smtp-in.l.google.com.
@ 3600 IN MX 30 alt3.gmr-smtp-in.l.google.com.
@ 3600 IN MX 40 alt4.gmr-smtp-in.l.google.com.

