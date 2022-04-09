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
  --sortOrder '+uid:2.5.13.6' \
  --virtualListView 0:2:1:1 \
  '(objectClass=person)'
```

Note: the ordering rule `2.5.13.6` is `caseExactOrderingMatch`.

If we capture the above request with [Wireshark](https://wireshark.org/),
we can see that the request is:

```
02 00 00 00 45 00 00 e3 00 00 40 00 40 06 00 00   ....E.....@.@...
7f 00 00 01 7f 00 00 01 d8 5f 01 85 9d 64 ea 73   ........._...d.s
af 77 1e fa 80 18 18 eb fe d7 00 00 01 01 08 0a   .w..............
1a d2 0d 02 1a d2 0c fe 30 81 ac 02 01 02 63 46   ........0.....cF
04 17 64 63 3d 70 6c 61 6e 65 74 65 78 70 72 65   ..dc=planetexpre
73 73 2c 64 63 3d 63 6f 6d 0a 01 02 0a 01 00 02   ss,dc=com.......
01 00 02 01 00 01 01 00 a3 15 04 0b 6f 62 6a 65   ............obje
63 74 43 6c 61 73 73 04 06 70 65 72 73 6f 6e 30   ctClass..person0
05 04 03 75 69 64 a0 5f 30 2d 04 16 31 2e 32 2e   ...uid._0-..1.2.
38 34 30 2e 31 31 33 35 35 36 2e 31 2e 34 2e 34   840.113556.1.4.4
37 33 04 13 30 11 30 0f 04 03 75 69 64 80 08 32   73..0.0...uid..2
2e 35 2e 31 33 2e 36 30 2e 04 17 32 2e 31 36 2e   .5.13.60...2.16.
38 34 30 2e 31 2e 31 31 33 37 33 30 2e 33 2e 34   840.1.113730.3.4
2e 39 01 01 ff 04 10 30 0e 02 01 00 02 01 02 a0   .9.....0........
06 02 01 01 02 01 01                              .......

```

And thus the controls are:

```
30 2d 04 16 31 2e 32 2e 38 34 30 2e 31 31 33 35
35 36 2e 31 2e 34 2e 34 37 33 04 13 30 11 30 0f
04 03 75 69 64 80 08 32 2e 35 2e 31 33 2e 36 30
2e 04 17 32 2e 31 36 2e 38 34 30 2e 31 2e 31 31
33 37 33 30 2e 33 2e 34 2e 39 01 01 ff 04 10 30
0e 02 01 00 02 01 02 a0 06 02 01 01 02 01 01

```

Specifically, the Server Side Sorting control is:

```
30 2d 04 16 31 2e 32 2e 38 34 30 2e 31 31 33 35
35 36 2e 31 2e 34 2e 34 37 33 04 13 30 11 30 0f
04 03 75 69 64 80 08 32 2e 35 2e 31 33 2e 36
```

And the Virtual List View control is:

```
30 2e 04 17 32 2e 31 36 2e 38 34 30 2e 31 2e 31
31 33 37 33 30 2e 33 2e 34 2e 39 01 01 ff 04 10
30 0e 02 01 00 02 01 02 a0 06 02 01 01 02 01 01
```

Finally, the resulting response is:

```
02 00 00 00 45 00 00 65 00 00 40 00 40 06 00 00   ....E..e..@.@...
7f 00 00 01 7f 00 00 01 01 85 d8 5f af 77 21 35   ..........._.w!5
9d 64 eb 22 80 18 18 e8 fe 59 00 00 01 01 08 0a   .d.".....Y......
1a d2 0d 0e 1a d2 0d 08 30 2f 02 01 02 65 07 0a   ........0/...e..
01 00 04 00 04 00 a0 21 30 1f 04 16 31 2e 32 2e   .......!0...1.2.
38 34 30 2e 31 31 33 35 35 36 2e 31 2e 34 2e 34   840.113556.1.4.4
37 34 04 05 30 03 0a 01 00                        74..0....
```

The end result being that a `SortResult` control is included but not a
`VLVResponse` control. Thus, we conclude that at this time Apache Directory
Server does not actually support the VLV control. This is despite the server
returning the control as supported when querying for the list of supported
controls.
