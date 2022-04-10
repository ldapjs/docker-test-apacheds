# docker-test-apacheds

The purpose of this repository is to provide an [Apache
DS](https://directory.apache.org/apacheds/) Docker image that can be used for
integration testing. The main goal being to be able to test the VirtualListView
control.

## Building And Running

1. Run `build.sh` to generate the image
2. Run `docker run --rm -it -p 389:10389 --name apacheds apacheds` to start
a server

## Testing The VLV Control

Using the `ldapsearch` tool from the [UnboundId
SDK](https://github.com/pingidentity/ldapsdk/releases), we can issue a search
that contains the VLV control by:

```sh
/ldapsearch --hostname localhost --port 389 \
  --bindDN 'uid=admin,ou=system' --bindPassword 'secret' \
  --baseDN 'dc=planetexpress,dc=com' \
  --requestedAttribute 'uid' \
  --sortOrder '-uid:2.5.13.6' \
  --virtualListView 0:2:1:1 \
  '(objectClass=person)'
```

Note: the ordering rule `2.5.13.6` is `caseExactOrderingMatch`.

If we capture the above request with [Wireshark](https://wireshark.org/), we can
see that the request is (capture file is available as
[vlv-tcp-capture.pcap](/assets/vlv-tcp-capture.pcap) in `/assets`):

```
30 81 af 02 01 02 63 46 04 17 64 63 3d 70 6c 61   0.....cF..dc=pla
6e 65 74 65 78 70 72 65 73 73 2c 64 63 3d 63 6f   netexpress,dc=co
6d 0a 01 02 0a 01 00 02 01 00 02 01 00 01 01 00   m...............
a3 15 04 0b 6f 62 6a 65 63 74 43 6c 61 73 73 04   ....objectClass.
06 70 65 72 73 6f 6e 30 05 04 03 75 69 64 a0 62   .person0...uid.b
30 30 04 16 31 2e 32 2e 38 34 30 2e 31 31 33 35   00..1.2.840.1135
35 36 2e 31 2e 34 2e 34 37 33 04 16 30 14 30 12   56.1.4.473..0.0.
04 03 75 69 64 80 08 32 2e 35 2e 31 33 2e 36 81   ..uid..2.5.13.6.
01 ff 30 2e 04 17 32 2e 31 36 2e 38 34 30 2e 31   ..0...2.16.840.1
2e 31 31 33 37 33 30 2e 33 2e 34 2e 39 01 01 ff   .113730.3.4.9...
04 10 30 0e 02 01 00 02 01 02 a0 06 02 01 01 02   ..0.............
01 01                                             ..
```

And thus the controls are:

```
30 30 04 16 31 2e 32 2e 38 34 30 2e 31 31 33 35   00..1.2.840.1135
35 36 2e 31 2e 34 2e 34 37 33 04 16 30 14 30 12   56.1.4.473..0.0.
04 03 75 69 64 80 08 32 2e 35 2e 31 33 2e 36 81   ..uid..2.5.13.6.
01 ff 30 2e 04 17 32 2e 31 36 2e 38 34 30 2e 31   ..0...2.16.840.1
2e 31 31 33 37 33 30 2e 33 2e 34 2e 39 01 01 ff   .113730.3.4.9...
04 10 30 0e 02 01 00 02 01 02 a0 06 02 01 01 02   ..0.............
01 01                                             ..
```

Specifically, the Server Side Sorting control is:

```
30 30 04 16 31 2e 32 2e 38 34 30 2e 31 31 33 35   00..1.2.840.1135
35 36 2e 31 2e 34 2e 34 37 33 04 16 30 14 30 12   56.1.4.473..0.0.
04 03 75 69 64 80 08 32 2e 35 2e 31 33 2e 36 81   ..uid..2.5.13.6.
01 ff                                             ..
```

And the Virtual List View control is:

```
30 2e 04 17 32 2e 31 36 2e 38 34 30 2e 31 2e 31   0...2.16.840.1.1
31 33 37 33 30 2e 33 2e 34 2e 39 01 01 ff 04 10   13730.3.4.9.....
30 0e 02 01 00 02 01 02 a0 06 02 01 01 02 01 01   0...............
```

Finally, the resulting response is:

```
30 2f 02 01 02 65 07 0a 01 00 04 00 04 00 a0 21   0/...e.........!
30 1f 04 16 31 2e 32 2e 38 34 30 2e 31 31 33 35   0...1.2.840.1135
35 36 2e 31 2e 34 2e 34 37 34 04 05 30 03 0a 01   56.1.4.474..0...
00                                                .
```

The end result being that a `SortResult` control is included but not a
`VLVResponse` control. Thus, we conclude that at this time Apache Directory
Server does not actually support the VLV control. This is despite the server
returning the control as supported when querying for the list of supported
controls.

This seems to be confirmed by https://issues.apache.org/jira/browse/DIRSERVER-1265
