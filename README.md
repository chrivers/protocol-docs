# Transwarp fork of Artemis Protocol Docs #

This is a fork of the
[Artemis Nerds](https://github.com/artemis-nerds/protocol-docs)
documentation repository, with the purpose of converting the
documentation into a
[transwarp](https://github.com/chrivers/transwarp) template.

## Getting started ##

Start by checking out the transwarp branch of the documenation out:

```capnp
$ git clone https://github.com/chrivers/protocol-docs.git -b transwarp transwarp-docs
$ cd transwarp-docs

# initialize the protocol specification submodule
$ git submodule update --init
```

Now just install the transwarp tool:

```
$ git clone https://github.com/chrivers/transwarp transwarp-compiler
$ cd transwarp-compiler
$ ./setup.py -q install
```

Now you are ready to rock and roll! To run a diff, simple do

```capnp
# this simply runs "transwarp -D isolinear-chips/protocol" from the Makefile
$ make
[*] Diffing 1 of 1 templates
[*]   index.html                       unchanged (updating timestamp)

# now that the timestamp is updated, you should see now changes:
[*] All templates up-to-date
```

## Online version ##

https://artemis-nerds.github.io/protocol-docs/](httpshttps://artemis-nerds.github.io/protocol-docs

View the documentation at [https://chrivers.github.io/protocol-docs/](https://chrivers.github.io/protocol-docs/).
