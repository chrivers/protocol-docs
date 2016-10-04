<%
import re
import html

re_camel_case = re.compile(r'(((?<=[a-z])[A-Z])|([A-Z](?![A-Z]|$)))')

def visit(parser, packet, res, origin):
    frametypes = enums.get("FrameType")
    for field in parser.fields:
        type_id = frametypes.fields.get(field.name).aligned_hex_value
        if field.type.name == "struct":
            name = field.type[0].name.split("::")[-1]
            res[name] = (packet.fields.get(name), type_id, None, None, origin)
        elif field.type.name == "parser":
            prs = parsers.get(field.type[0].name)
            for fld in prs.fields:
                name = fld.type[0].name.split("::")[-1]
                res[name] = (packet.fields.get(name), type_id, fld.name, prs.arg, origin)

packet_ids = dict()
visit(parsers.get("ClientParser"), packets.get("ClientPacket"), packet_ids, "client")
visit(parsers.get("ServerParser"), packets.get("ServerPacket"), packet_ids, "server")

def split_camelcase(value):
    """Splits CamelCase. Also strips leading and trailing whitespace."""
    return re_camel_case.sub(r' \1', value).strip().split()

def camelcase_to_id(value):
    return "-".join(split_camelcase(value)).lower()

def camelcase_to_name(value):
    return " ".join(split_camelcase(value))

def index_to_bit(index):
    return "%d.%d" % (index // 8 + 1, index % 8 + 1)

def format_comment(lines):
    return " ".join([html.escape(line) for line in util.format_comment(lines, indent="", width=80)])

def packets_by_prefix(letter):
    all_packets = sorted(packet_ids.keys())
    for pkt in all_packets:
        if pkt.startswith(letter):
            yield pkt, packet_ids[pkt]

def format_packet_id(packet_id):
    major, minor = packet_id[1], packet_id[2]
    if minor:
        return "<code>%s</code>:<code>%s</code>" % (major, minor)
    else:
        return "<code>%s</code>" % major

%>\
<%def name="present_type(type)">\
% if type.name == "enum":
enum ${type[1].name} as ${type[0].name}\
% elif type.name in ("u8", "u16", "u32", "u64", "i8", "i16", "i32", "i64", "bool8", "bool16", "bool32"):
${type.name}\
% elif type.name == "f32":
float\
% elif type.name == "string":
string\
% elif type.name == "struct":
struct ${type[0].name}\
% elif type.name == "ascii_string":
ascii string\
% elif type.name == "array" and type[1]:
array of ${present_type(type[0])}, terminated by ${type[1].name}\
% elif type.name == "array":
array of ${present_type(type[0])}\
% elif type.name == "sizedarray":
${present_type(type[0])} array (length ${type[1].name})\
% elif type.name == "bitflags":
${type[1].name} as ${type[0].name}\
% else:
${type}\
% endif
</%def>\
<%def name="present_name(name)">\
% if name.startswith("__"):
${name}\
% else:
${name.replace("_", " ").title().strip()}\
% endif
</%def>\
<%def name="present_property(field, index)">\
% if field.type.name == "sizedarray":
${present_name(field.name)} (${present_type(field.type)})\
% else:
${present_name(field.name)} (bit ${index_to_bit(index)}, ${present_type(field.type)})\
% endif
</%def>\
<%def name="present_field(field)">\
${present_name(field.name)} (${present_type(field.type)})\
</%def>\
<%def name="section(prefix, start=True, end=True)">\
% if start:
          <section id="pkt-${prefix[:1].lower()}">
            <h3>${prefix[:1]}</h3>
% endif
            % for packet, packet_id in packets_by_prefix(prefix):
            <section id="${packet.lower()}packet">
              <h3>${packet}Packet</h3>
              <div class="pkt-props">Type: ${format_packet_id(packet_id)} [from <span>${packet_id[4]}</span>]</div>
              <p>
                ${format_comment(packet_id[0].comment)}
              </p>
              <h4>Payload</h4>
              <dl>
              % if packet_id[2]:
                <dt>Subtype (${packet_id[3]})</dt>
                <dd>
                  <p>
                    Always <code>${packet_id[2]}</code>.
                  </p>
                </dd>
              % endif
              % for field in packet_id[0].fields:
                <dt>${present_field(field)}</dt>
                <dd>
                  <p>
                    ${format_comment(field.comment)}
                  </p>
                </dd>
              % endfor
              </dl>
            </section>
            % endfor
% if end:
          </section>
% endif
</%def>\
<%def name="render_enum(enum)">
          <section id="enum-ship-system">
            <h3>${camelcase_to_name(enum.name)}</h3>
            <table>
              <tbody>
                % for item in enum.fields:
                <tr>
                  <td><code>${item.aligned_hex_value}</code></td>
                  <td>${item.name}</td>
                </tr>
                % endfor
              </tbody>
            </table>
          </section>
</%def>\
\
\
<!DOCTYPE html>
<html>
  <head>
    <title>Artemis Protocols</title>
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.4/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.4/css/bootstrap-theme.min.css">
    <link rel="stylesheet" href="style.css">
    <script src="https://code.jquery.com/jquery-2.1.4.min.js"></script>
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.4/js/bootstrap.min.js"></script>
    <script src="script.js"></script>
  </head>
  <body class="container">
    <div class="row">
      <nav class="navsidebar col-xs-3">
        <ul id="sidebar" class="nav nav-stacked"></ul>
      </nav>
      <content class="col-xs-9">
        <h1>Artemis Protocols</h1>
        <section id="intro">
          <h2>Introduction</h2>
          <p>
            This is unoffical documentation of the network and file protocols used by
            <a href="http://www.artemis.eochu.com/" target="_new"><cite>Artemis Spaceship Bridge Simulator</cite></a>.
            No official documentation exists, so the information in this document has been obtained
            through community reverse-engineering efforts. There will be parts of the protocols that
            are not completely documented because their purpose has not been determined, and some
            parts may not be accurate. Contributions to this documentation are welcome.
          </p>
        </section>

        <section id="data-types">
          <h2>Data Types</h2>
          <p>
            The Artemis protocols use the following data types:
            <ul>
              <li>byte</li>
              <li>short (2 bytes)</li>
              <li>int (4 bytes)</li>
              <li>float (4 bytes)</li>
              <li>bit field (variable length)</li>
              <li>boolean (variable length)</li>
              <li>string (variable length)</li>
            </ul>
          </p>
          <p>
            These types can be combined in <em>structs</em> or <em>arrays</em>.
          </p>
          <section id="endianness">
            <h3>Endianness</h3>
            <p>
              All multi-byte data types are represented in
              <a href="https://en.wikipedia.org/wiki/Endianness" target="_new">little-endian</a>
              order (least-significant byte first). Numeric literals in this documentation, in order
              to follow the existing convention for many programming languages, are prefixed with
              <code>0x</code> and are written in big-endian order. For example, the four bytes that
              begin every Artemis packet are <code>ef be ad de</code>; represented as an int, this
              is <code>0xdeadbeef</code>.
            </p>
          </section>
          <section id="numeric-format">
            <h3>Numeric Format</h3>
            <p>
              Integral types (byte, short, int) use
              <a href="https://en.wikipedia.org/wiki/Two%27s_complement" target="_new">two's complement</a>
              representation in binary. Floats use
              <a href="https://en.wikipedia.org/wiki/IEEE_floating_point" target="_new">IEEE 754 binary32 format</a>.
            </p>
          </section>
          <section id="bit-field-format">
            <h3>Bit Field Format</h3>
            <p>
              A bit field is one or more bytes that encodes a series of on/off switches. Each bit in
              the binary representation of each byte in the field represents a single switch. In
              this documentation, an individual bit in a bit field is represented with the notation
              &ldquo;bit <em>{byte}</em>.<em>{bit}</em>&rdquo;, where the <em>byte</em> and
              <em>bit</em> values are one-based, and the bits are counted in little-endian order
              (least-significant bits first).
            </p>
            <p>
              The most common use for a bit field is to declare which properties are defined
              in a struct. Each bit represents a property, with <code>1</code> indicating that the
              property is defined, and <code>0</code> meaning it is undefined. When sending updates
              to clients, the Artemis server typically omits properties which are unchanged since
              the last update; these properties will be undefined when the updated struct is
              transmitted.
            </p>
            <h4>Example</h4>
            <p>
              A single-byte bit field with the value <code>0x42</code> is represented in
              little-endian binary as <code>01000010</code>. Bits 1.2 and 1.7 are on, the rest are
              off.
            </p>
          </section>
          <section id="boolean-format">
            <h3>Boolean Format</h3>
            <p>
              Boolean values are simply expressed as an integer value 0 (false) or 1 (true). This
              value may be transmitted as a byte, short or int. In this documentation, a field is
              considered to be a boolean if all the following conditions are met:
            </p>
            <ol>
              <li>There are only two possible values.</li>
              <li>The values are exact opposites (true/false, on/off, etc.).</li>
              <li>They are represented by 0 and 1.</li>
              <li>It does not seem that other values could be added in the future. (If other values
                are deemed possible, the field's value is documented as an
                <a href="#enums">enumeration</a> instead.)</li>
            </ol>
          </section>
          <section id="string-format">
            <h3>String Format</h3>
            <p>
              Strings are represented by an int giving the length of the string in characters,
              followed by the string itself encoded in
              <a href="https://en.wikipedia.org/wiki/UTF-16" target="_new">UTF-16LE</a>.
              Because UTF-16 encodes each character in two bytes, the number of bytes to read after
              the length value is the number of characters times two. Strings are null-terminated
              (<code>0x0000</code>), and the length value includes the null. Under normal
              circumstances, the null character would be the last two bytes read for the string; if
              the null character occurs earlier, the remaining bytes are meaningless and should be
              discarded. Zero-length strings are not allowed. For brevity's sake, all values denoted
              as strings in this documentation are presumed to follow this format, and the string
              length value will not be documented separately.
            </p>
            <h4>Example</h4>
            <p>
              To interpret the byte sequence <code>04 00 00 00 48 00 69 00 21 00 00 00</code> as a
              string, you would first read an int (4 bytes) to learn the string's length:
              <code>04 00 00 00</code>, which is four characters. In UTF-16, this is eight bytes, so
              you'd then read eight bytes from the stream: <code>48 00 69 00 21 00 00 00</code>.
              Decoded, this is <code>H</code>, <code>i</code>, <code>!</code> and <code>null</code>,
              which terminates the string. Thus, the byte sequence represents the string "Hi!"
            </p>
            <h3>Array Format</h3>
            <p>
              Arrays consist of an ordered list of values. These values can be primitive types,
              strings, structs or other arrays. There are two basic kinds of arrays: delimited and
              undelimited. Delimited arrays are typically used in circumstances where the exact
              number of elements in the array is not known in advance. Elements are transmitted one
              after the other until a particular byte is encountered instead of more data. With
              undelimited arrays, either the exact size or exact number of elements is known, so no
              delimiter is needed. Instead, parsing continues until the desired number of elements
              is read, or all the bytes that make up the array are consumed.
            </p>
            <h3>Structs</h3>
            <p>
              Structs are complex types composed of primitive types, strings, arrays or other
              structs. These properties are always specified in a particular defined order, so that
              it is unneccessary to declare each property's name when reading or writing a struct.
              There are two type of structs: static structs and bit field structs. A static struct
              always transmits all of its properties. A bit field struct has a bit field as its
              first property. Each bit in the field corresponds to one of the remaining properties
              in the struct. If a bit is <code>1</code>, that property is defined; if it's
              <code>0</code>, it is undefined and is omitted from the struct. When the Artemis
              server sends game object updates, it will typically use bit field structs to only send
              properties which have changed and leave the rest undefined; this reduces the payload
              size for update packets.
            </p>
          </section>
        </section>

        <section id="enums">
          <h2>Enumerations</h2>
          <p>
            When <em>Artemis</em> needs to refer to an item from a static list (enumeration), it
            will use a predefined numeric value to represent it. This section documents these
            enumerations.
          </p>
          <section id="enum-alert-status">
            <h3>Alert Status</h3>
            <table>
              <tbody>
                <tr>
                  <td><code>0x00</code></td>
                  <td>normal</td>
                </tr>
                <tr>
                  <td><code>0x01</code></td>
                  <td>red alert</td>
                </tr>
              </tbody>
            </table>
          </section>
          <section id="enum-audio-command">
            <h3>Audio Command</h3>
            <table>
              <tbody>
                <tr>
                  <td><code>0x00</code></td>
                  <td>play</td>
                </tr>
                <tr>
                  <td><code>0x01</code></td>
                  <td>dismiss</td>
                </tr>
              </tbody>
            </table>
          </section>
          <section id="enum-audio-mode">
            <h3>Audio Mode</h3>
            <table>
              <tbody>
                <tr>
                  <td><code>0x00</code></td>
                  <td><em>unused</em></td>
                </tr>
                <tr>
                  <td><code>0x01</code></td>
                  <td>playing</td>
                </tr>
                <tr>
                  <td><code>0x02</code></td>
                  <td>incoming</td>
                </tr>
              </tbody>
            </table>
          </section>
          <section id="enum-beam-frequency">
            <h3>Beam Frequency</h3>
            <table>
              <tbody>
                <tr>
                  <td><code>0x00</code></td>
                  <td>A</td>
                </tr>
                <tr>
                  <td><code>0x01</code></td>
                  <td>B</td>
                </tr>
                <tr>
                  <td><code>0x02</code></td>
                  <td>C</td>
                </tr>
                <tr>
                  <td><code>0x03</code></td>
                  <td>D</td>
                </tr>
                <tr>
                  <td><code>0x04</code></td>
                  <td>E</td>
                </tr>
              </tbody>
            </table>
          </section>
          <section id="enum-comm-message">
            <h3>COMM Message</h3>
            <p>
              To players:
            </p>
            <table>
              <tbody>
                <tr>
                  <td><code>0x00</code></td>
                  <td>Yes.</td>
                </tr>
                <tr>
                  <td><code>0x01</code></td>
                  <td>No.</td>
                </tr>
                <tr>
                  <td><code>0x02</code></td>
                  <td>Help!</td>
                </tr>
                <tr>
                  <td><code>0x03</code></td>
                  <td>Greetings.</td>
                </tr>
                <tr>
                  <td><code>0x04</code></td>
                  <td>Die!</td>
                </tr>
                <tr>
                  <td><code>0x05</code></td>
                  <td>We're leaving the sector. Bye.</td>
                </tr>
                <tr>
                  <td><code>0x06</code></td>
                  <td>Ready to go.</td>
                </tr>
                <tr>
                  <td><code>0x07</code></td>
                  <td>Please follow us.</td>
                </tr>
                <tr>
                  <td><code>0x08</code></td>
                  <td>We'll follow you.</td>
                </tr>
                <tr>
                  <td><code>0x09</code></td>
                  <td>We're badly damaged.</td>
                </tr>
                <tr>
                  <td><code>0x0a</code></td>
                  <td>We're headed back to the station.</td>
                </tr>
                <tr>
                  <td><code>0x0b</code></td>
                  <td>Sorry, please disregard.</td>
                </tr>
              </tbody>
            </table>
            <p>
              To enemies:
            </p>
            <table>
              <tbody>
                <tr>
                  <td><code>0x00</code></td>
                  <td>Will you surrender?</td>
                </tr>
                <tr>
                  <td><code>0x01</code></td>
                  <td>Taunt #1 (varies by race)</td>
                </tr>
                <tr>
                  <td><code>0x02</code></td>
                  <td>Taunt #2 (varies by race)</td>
                </tr>
                <tr>
                  <td><code>0x03</code></td>
                  <td>Taunt #3 (varies by race)</td>
                </tr>
              </tbody>
            </table>
            <p>
              To stations:
            </p>
            <table>
              <tbody>
                <tr>
                  <td><code>0x00</code></td>
                  <td>Stand by for docking.</td>
                </tr>
                <tr>
                  <td><code>0x01</code></td>
                  <td>Please report status.</td>
                </tr>
                <tr>
                  <td><code>0x02</code></td>
                  <td>Build homing missiles</td>
                </tr>
                <tr>
                  <td><code>0x03</code></td>
                  <td>Build nukes</td>
                </tr>
                <tr>
                  <td><code>0x04</code></td>
                  <td>Build mines</td>
                </tr>
                <tr>
                  <td><code>0x05</code></td>
                  <td>Build EMPs</td>
                </tr>
                <tr>
                  <td><code>0x06</code></td>
                  <td>Build PShocks</td>
                </tr>
              </tbody>
            </table>
            <p>
              To other ships:
            </p>
            <table>
              <tbody>
                <tr>
                  <td><code>0x00</code></td>
                  <td>Report status</td>
                </tr>
                <tr>
                  <td><code>0x01</code></td>
                  <td>Turn to heading 0</td>
                </tr>
                <tr>
                  <td><code>0x02</code></td>
                  <td>Turn to heading 90</td>
                </tr>
                <tr>
                  <td><code>0x03</code></td>
                  <td>Turn to heading 180</td>
                </tr>
                <tr>
                  <td><code>0x04</code></td>
                  <td>Turn to heading 270</td>
                </tr>
                <tr>
                  <td><code>0x05</code></td>
                  <td>Turn 10 degrees to port</td>
                </tr>
                <tr>
                  <td><code>0x06</code></td>
                  <td>Turn 10 degrees to starboard</td>
                </tr>
                <tr>
                  <td><code>0x07</code></td>
                  <td>Attack nearest enemy</td>
                </tr>
                <tr>
                  <td><code>0x08</code></td>
                  <td>Proceed to your destination</td>
                </tr>
                <tr>
                  <td><code>0x09</code></td>
                  <td>Go defend [target]</td>
                </tr>
                <tr>
                  <td><code>0x0a</code></td>
                  <td><em>unused</em></td>
                </tr>
                <tr>
                  <td><code>0x0b</code></td>
                  <td><em>unused</em></td>
                </tr>
                <tr>
                  <td><code>0x0c</code></td>
                  <td><em>unused</em></td>
                </tr>
                <tr>
                  <td><code>0x0d</code></td>
                  <td><em>unused</em></td>
                </tr>
                <tr>
                  <td><code>0x0e</code></td>
                  <td><em>unused</em></td>
                </tr>
                <tr>
                  <td><code>0x0f</code></td>
                  <td>Turn 25 degrees to port</td>
                </tr>
                <tr>
                  <td><code>0x10</code></td>
                  <td>Turn 25 degrees to starboard</td>
                </tr>
              </tbody>
            </table>
          </section>
          <section id="enum-comm-target-type">
            <h3>COMM Target Type</h3>
            <table>
              <tbody>
                <tr>
                  <td><code>0x00</code></td>
                  <td>player</td>
                </tr>
                <tr>
                  <td><code>0x01</code></td>
                  <td>enemy</td>
                </tr>
                <tr>
                  <td><code>0x02</code></td>
                  <td>station</td>
                </tr>
                <tr>
                  <td><code>0x03</code></td>
                  <td>other</td>
                </tr>
              </tbody>
            </table>
          </section>
          <section id="enum-connection-type">
            <h3>Connection Type</h3>
            <table>
              <tbody>
                <tr>
                  <td><code>0x00</code></td>
                  <td><em>unused</em></td>
                </tr>
                <tr>
                  <td><code>0x01</code></td>
                  <td>server</td>
                </tr>
                <tr>
                  <td><code>0x02</code></td>
                  <td>client</td>
                </tr>
              </tbody>
            </table>
          </section>
          <section id="enum-console-status">
            <h3>Console Status</h3>
            <table>
              <tbody>
                <tr>
                  <td><code>0x00</code></td>
                  <td>available</td>
                </tr>
                <tr>
                  <td><code>0x01</code></td>
                  <td>yours</td>
                </tr>
                <tr>
                  <td><code>0x02</code></td>
                  <td>unavailable</td>
                </tr>
              </tbody>
            </table>
          </section>
          <section id="enum-console-type">
            <h3>Console Type</h3>
            <table>
              <thead>
                <tr>
                  <th></th>
                  <th>&lt; v2.1</th>
                  <th>&ge; v2.1, &lt; v2.3</th>
                  <th>&ge; v2.3</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td><code>0x00</code></td>
                  <td>main screen</td>
                  <td>main screen</td>
                  <td>main screen</td>
                </tr>
                <tr>
                  <td><code>0x01</code></td>
                  <td>helm</td>
                  <td>helm</td>
                  <td>helm</td>
                </tr>
                <tr>
                  <td><code>0x02</code></td>
                  <td>weapons</td>
                  <td>weapons</td>
                  <td>weapons</td>
                </tr>
                <tr>
                  <td><code>0x03</code></td>
                  <td>engineering</td>
                  <td>engineering</td>
                  <td>engineering</td>
                </tr>
                <tr>
                  <td><code>0x04</code></td>
                  <td>science</td>
                  <td>science</td>
                  <td>science</td>
                </tr>
                <tr>
                  <td><code>0x05</code></td>
                  <td>communications</td>
                  <td>communications</td>
                  <td>communications</td>
                </tr>
                <tr>
                  <td><code>0x06</code></td>
                  <td>observer</td>
                  <td>data</td>
                  <td>fighter</td>
                </tr>
                <tr>
                  <td><code>0x07</code></td>
                  <td>captain's map</td>
                  <td>observer</td>
                  <td>data</td>
                </tr>
                <tr>
                  <td><code>0x08</code></td>
                  <td>game master</td>
                  <td>captain's map</td>
                  <td>observer</td>
                </tr>
                <tr>
                  <td><code>0x09</code></td>
                  <td><em>unused</em></td>
                  <td>game master</td>
                  <td>captain's map</td>
                </tr>
                <tr>
                  <td><code>0x0a</code></td>
                  <td><em>unused</em></td>
                  <td><em>unused</em></td>
                  <td>game master</td>
                </tr>
              </tbody>
            </table>
          </section>
          <section id="enum-creature-type">
            <h3>Creature Type</h3>
            <p>
              New as of v2.1.5.
            </p>
            <table>
              <tbody>
                <tr>
                  <td><code>0x00</code></td>
                  <td>classic monster</td>
                </tr>
                <tr>
                  <td><code>0x01</code></td>
                  <td>whale</td>
                </tr>
                <tr>
                  <td><code>0x02</code></td>
                  <td>shark</td>
                </tr>
                <tr>
                  <td><code>0x03</code></td>
                  <td>dragon</td>
                </tr>
                <tr>
                  <td><code>0x04</code></td>
                  <td>piranha</td>
                </tr>
                <tr>
                  <td><code>0x05</code></td>
                  <td>charybdis</td>
                </tr>
                <tr>
                  <td><code>0x06</code></td>
                  <td>insect</td>
                </tr>
                <tr>
                  <td><code>0x07</code></td>
                  <td>wreck</td>
                </tr>
              </tbody>
            </table>
          </section>
          <section id="enum-drive-type">
            <h3>Drive Type</h3>
            <table>
              <tbody>
                <tr>
                  <td><code>0x00</code></td>
                  <td>warp</td>
                </tr>
                <tr>
                  <td><code>0x01</code></td>
                  <td>jump</td>
                </tr>
              </tbody>
            </table>
          </section>
          <section id="enum-special-ability">
            <h3>Special Ability</h3>
            <p>
              Note: Special abilities can stack, in which case the values are ORed together. For
              example, cloak and warp would be <code>0x14</code>. A ship with no special abilities
              would have a special ability value of <code>0x00</code>.

              Special abilities used to be called <emph>elite
              abilities</emph> in earlier versions of the game.
            </p>
            <table>
              <thead>
                <tr><th>Flag</th><th>Internal name</th><th>Alt name</th><th>Description</th></tr>
              </thead>
              <tbody>
                <tr><td><code>0x0001</code></td><td>ELITE_INVIS_TO_MAIN_SCREEN</td><td>Stealth</td><td>Cannot be seen on main screen</td></tr>
                <tr><td><code>0x0002</code></td><td>ELITE_INVIS_TO_TACTICAL   </td><td>LowVis</td><td>Cannot be seen on tactical map</td></tr>
                <tr><td><code>0x0004</code></td><td>ELITE_CLOAKING            </td><td>Cloak</td><td>Can become completely invisible</td></tr>
                <tr><td><code>0x0008</code></td><td>ELITE_HET                 </td><td>HET</td><td>?</td></tr>
                <tr><td><code>0x0010</code></td><td>ELITE_WARP                </td><td>Warp</td><td>?</td></tr>
                <tr><td><code>0x0020</code></td><td>ELITE_TELEPORT            </td><td>Teleport</td><td>?</td></tr>
                <tr><td><code>0x0040</code></td><td>ELITE_TRACTOR_BEAM        </td><td>Tractor</td><td>Can lock player ships in, preventing them from escaping</td></tr>
                <tr><td><code>0x0080</code></td><td>ELITE_DRONE_LAUNCHER      </td><td>Drones</td><td>Can launch drones</td></tr>
                <tr><td><code>0x0100</code></td><td>ELITE_ANTI_MINE_BEAMS     </td><td>Anti-mines</td><td>?</td></tr>
                <tr><td><code>0x0200</code></td><td>ELITE_ANTI_TORP_BEAMS     </td><td>Anti-torp</td><td>?</td></tr>
                <tr><td><code>0x0400</code></td><td>ELITE_ANTI_SHIELD         </td><td>Shield-drain</td><td>Can drain the energy of player ship shields</td></tr>
                <tr><td><code>0x0800</code></td><td>ELITE_?                   </td><td>ShldVamp</td><td>Can steal energy from player ship shields (unconfirmed)</td></tr>
              </tbody>
            </table>
          </section>
          <section id="enum-game-type">
            <h3>Game Type</h3>
            <table>
              <thead>
                <tr>
                  <th></th>
                  <th>&lt; v2.1</th>
                  <th>&ge; v2.1</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td><code>0x00</code></td>
                  <td>siege</td>
                  <td>siege</td>
                </tr>
                <tr>
                  <td><code>0x01</code></td>
                  <td>single front</td>
                  <td>single front</td>
                </tr>
                <tr>
                  <td><code>0x02</code></td>
                  <td>double front</td>
                  <td>double front</td>
                </tr>
                <tr>
                  <td><code>0x03</code></td>
                  <td><em>unused</em></td>
                  <td>deep strike</td>
                </tr>
                <tr>
                  <td><code>0x04</code></td>
                  <td><em>unused</em></td>
                  <td>peacetime</td>
                </tr>
                <tr>
                  <td><code>0x05</code></td>
                  <td><em>unused</em></td>
                  <td>border war</td>
                </tr>
              </tbody>
            </table>
          </section>
          <section id="enum-main-screen-view">
            <h3>Main Screen View</h3>
            <table>
              <tbody>
                % for enum in enums.get("MainScreenView").fields:
                <tr>
                  <td><code>${enum.aligned_hex_value}</code></td>
                  <td>${enum.name}</td>
                </tr>
                % endfor
              </tbody>
            </table>
          </section>
          <section id="enum-object-type">
            <h3>Object Type</h3>
            <table>
              <thead>
                <tr>
                  <th></th>
                  <th>&lt; v2.1.5</th>
                  <th>&ge; v2.1.5</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td><code>0x00</code></td>
                  <td><em>end of ObjectUpdatePacket</em></td>
                  <td><em>end of ObjectUpdatePacket</em></td>
                </tr>
                <tr>
                  <td><code>0x01</code></td>
                  <td>player ship</td>
                  <td>player ship</td>
                </tr>
                <tr>
                  <td><code>0x02</code></td>
                  <td>weapons console</td>
                  <td>weapons console</td>
                </tr>
                <tr>
                  <td><code>0x03</code></td>
                  <td>engineering console</td>
                  <td>engineering console</td>
                </tr>
                <tr>
                  <td><code>0x04</code></td>
                  <td>NPC ship (enemy or civilian)</td>
                  <td>player ship upgrades</td>
                </tr>
                <tr>
                  <td><code>0x05</code></td>
                  <td>base</td>
                  <td>NPC ship (enemy or civilian)</td>
                </tr>
                <tr>
                  <td><code>0x06</code></td>
                  <td>mine</td>
                  <td>base</td>
                </tr>
                <tr>
                  <td><code>0x07</code></td>
                  <td>anomaly</td>
                  <td>mine</td>
                </tr>
                <tr>
                  <td><code>0x08</code></td>
                  <td><em>unused</em></td>
                  <td>anomaly</td>
                </tr>
                <tr>
                  <td><code>0x09</code></td>
                  <td>nebula</td>
                  <td><em>unused</em></td>
                </tr>
                <tr>
                  <td><code>0x0a</code></td>
                  <td>torpedo</td>
                  <td>nebula</td>
                </tr>
                <tr>
                  <td><code>0x0b</code></td>
                  <td>black hole</td>
                  <td>torpedo</td>
                </tr>
                <tr>
                  <td><code>0x0c</code></td>
                  <td>asteroid</td>
                  <td>black hole</td>
                </tr>
                <tr>
                  <td><code>0x0d</code></td>
                  <td>generic mesh</td>
                  <td>asteroid</td>
                </tr>
                <tr>
                  <td><code>0x0e</code></td>
                  <td>creature</td>
                  <td>generic mesh</td>
                </tr>
                <tr>
                  <td><code>0x0f</code></td>
                  <td>whale</td>
                  <td>creature</td>
                </tr>
                <tr>
                  <td><code>0x10</code></td>
                  <td>drone</td>
                  <td>drone</td>
                </tr>
              </tbody>
            </table>
          </section>
          <section id="enum-ordnance-type">
            <h3>Ordnance Type</h3>
            <table>
              <thead>
                <tr>
                  <th></th>
                  <th>&lt; v2.1.5</th>
                  <th>&ge; v2.1.5</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td><code>0x00</code></td>
                  <td>homing missile</td>
                  <td>homing missile</td>
                </tr>
                <tr>
                  <td><code>0x01</code></td>
                  <td>nuke</td>
                  <td>nuke</td>
                </tr>
                </tr>
                  <td><code>0x02</code></td>
                  <td>mine</td>
                  <td>mine</td>
                </tr>
                <tr>
                  <td><code>0x03</code></td>
                  <td>EMP</td>
                  <td>EMP</td>
                </tr>
                <tr>
                  <td><code>0x04</code></td>
                  <td><em>unused</em></td>
                  <td>plasma shock</td>
                </tr>
              </tbody>
            </table>
          </section>
          <section id="enum-perspective">
            <h3>Perspective</h3>
            <table>
              <tbody>
                <tr>
                  <td><code>0x00</code></td>
                  <td>first person</td>
                </tr>
                <tr>
                  <td><code>0x01</code></td>
                  <td>third person</td>
                </tr>
              </tbody>
            </table>
          </section>
          ${render_enum(enums.get("ShipSystem"))}\
          <section id="enum-targeting-mode">
            <h3>Targeting Mode</h3>
            <table>
              <tbody>
                <tr>
                  <td><code>0x00</code></td>
                  <td>auto</td>
                </tr>
                <tr>
                  <td><code>0x01</code></td>
                  <td>manual</td>
                </tr>
              </tbody>
            </table>
          </section>

          <section id="enum-tube-status">
            <h3>Tube Status</h3>
            <table>
              <tbody>
                <tr>
                  <td><code>0x00</code></td>
                  <td>unloaded</td>
                </tr>
                <tr>
                  <td><code>0x01</code></td>
                  <td>loaded</td>
                </tr>
                <tr>
                  <td><code>0x02</code></td>
                  <td>loading</td>
                </tr>
                <tr>
                  <td><code>0x03</code></td>
                  <td>unloading</td>
                </tr>
              </tbody>
            </table>
          </section>

          <section id="enum-upgrade">
            <h3>Upgrades</h3>
            <p>
              New as of v2.1.5. Upgrades marked with (*) can be
              activated by client consoles, meaning they can occur in
              the ActivateUpgrade packet.
            </p>
            <table>
              <thead>
                <tr><th>Index</th><th>In-game name</th><th>Type</th><th>Description</th></tr>
              </thead>
              <tbody>
                <tr><td><code>0x00</code>*</td><td>Infusion P-Coils             </td><td>Engine Boost       </td><td>5 Minute 10% Impulse and Warp Speed Boost</td></tr>
                <tr><td><code>0x01</code>*</td><td>Hydrogen Ram                 </td><td>Maneuver Boost     </td><td>5 Minute 10% Turn Speed Boost</td></tr>
                <tr><td><code>0x02</code>*</td><td>Tauron Focusers              </td><td>Weapons Boost      </td><td>5 Minute 10% Beam and Reload Speed Boost</td></tr>
                <tr><td><code>0x03</code>*</td><td>Carapaction Coils            </td><td>Shield Boost       </td><td>5 Minute 10% Shield Recharge Boost</td></tr>
                <tr><td><code>0x04</code>*</td><td>Polyphasic Capacitors        </td><td>Energy Boost       </td><td>5 Minute 10% Energy Recharge Boost</td></tr>
                <tr><td><code>0x05</code>*</td><td>Coolant Reserves             </td><td>Heat Reduction     </td><td>5 Minute 10% Faster Heat Reduction</td></tr>
                <tr><td><code>0x06</code>*</td><td>Lateral Array                </td><td>Scanner Boost      </td><td>5 Minute Target Scan Triple Speed</td></tr>
                <tr><td><code>0x07</code>*</td><td>ECM Starpulse                </td><td>Jammer Boost       </td><td>5 Minute Enemy Cannot Lock</td></tr>
                <tr><td><code>0x08</code>*</td><td>Double Agent                 </td><td>Auto-Surrender     </td><td>Can force one ship to auto surrender</td></tr>
                <tr><td><code>0x09</code></td><td>Wartime Production           </td><td>Prod Boost         </td><td>10% (min +1) boost to all starting base munitions</td></tr>
                <tr><td><code>0x0a</code></td><td>Infusion P-Coils PERM        </td><td>Engine Refit       </td><td>Permanent 10% Impulse and Warp Speed Boost</td></tr>
                <tr><td><code>0x0b</code></td><td>Protonic Verniers            </td><td>Maneuver Refit     </td><td>Permanent 10% Turn Speed Boost</td></tr>
                <tr><td><code>0x0c</code></td><td>Tauron Focusers PERM         </td><td>Weapons Refit      </td><td>Permanent 10% Reload and Beam Speed</td></tr>
                <tr><td><code>0x0d</code></td><td>Regenerative Pau-Grids       </td><td>Shield Refit       </td><td>Permanent 10% Shield Recharge Speed</td></tr>
                <tr><td><code>0x0e</code></td><td>Veteran DamCon Teams         </td><td>Faster DamCon      </td><td>Damcon teams move/repair 10% faster</td></tr>
                <tr><td><code>0x0f</code></td><td>Cetrocite Heatsinks          </td><td>Heatsink Refit     </td><td>Heat builds 10% slower</td></tr>
                <tr><td><code>0x10</code></td><td>Tachyon Scanners             </td><td>Scanner Refit      </td><td>Permanent 10% Scan Speed Boost</td></tr>
                <tr><td><code>0x11</code></td><td>Gridscan Overload            </td><td>Sensor Refit       </td><td>Permanent 10% Range Booster</td></tr>
                <tr><td><code>0x12</code></td><td>Override Authorization       </td><td>Improved Prod      </td><td>All bases produce 10% faster</td></tr>
                <tr><td><code>0x13</code></td><td>Resupply Imperatives         </td><td>Mission Enhance    </td><td>10% More missions</td></tr>
                <tr><td><code>0x14</code></td><td>Patrol Group                 </td><td>Allied Combat      </td><td>Additional TSN Escort Ship in-sector</td></tr>
                <tr><td><code>0x15</code></td><td>Fast Supply                  </td><td>Allied Supply      </td><td>Additional TSN Cargo Ship in-sector</td></tr>
                <tr><td><code>0x16</code></td><td>Vanguard Refit               </td><td>Improved Console   </td><td>Perm 10% Boost to Impulse, Warp, and Turn Speed</td></tr>
                <tr><td><code>0x17</code></td><td>Vanguard Refit               </td><td>Improved Console   </td><td>Perm 10% Boost to Beam, Shield and Reload Speeds</td></tr>
                <tr><td><code>0x18</code></td><td>Vanguard Refit               </td><td>Improved Console   </td><td>Perm 10% Boost to Scan speed and Sensor Range</td></tr>
                <tr><td><code>0x19</code></td><td>Vanguard Refit               </td><td>Improved Console   </td><td>Perm 10% Boost to Station production</td></tr>
                <tr><td><code>0x1a</code></td><td>Vanguard Refit               </td><td>Improved Console   </td><td>Perm 10% Boost to all Engineering Systems</td></tr>
                <tr><td><code>0x1b</code></td><td>Vanguard Refit               </td><td>Systems Overhaul   </td><td>Permanent 10% Boost to all Ship Systems</td></tr>
              </tbody>
            </table>

            <h3>Game world upgrades</h3>
            <p>
              New as of v2.1.5.
            </p>
            <table>
              <thead>
                <tr><th>Index</th><th>Internal name</th><th>Known names</th></tr>
              </thead>
              <tbody>
                <tr><td><code>0x00</code></td><td>ITEMTYPE_ENERGY</td>        <td>Anomaly / HiDens Power Cell</td></tr>
                <tr><td><code>0x01</code></td><td>ITEMTYPE_RESTORE_DAMCON</td><td>Vigoranium Nodule</td></tr>
                <tr><td><code>0x02</code></td><td>ITEMTYPE_HEAT_BUFF</td>     <td>Cetrocite Crystal</td></tr>
                <tr><td><code>0x03</code></td><td>ITEMTYPE_SCAN_BUFF</td>     <td>Lateral Array</td></tr>
                <tr><td><code>0x04</code></td><td>ITEMTYPE_WEAP_BUFF</td>     <td>Tauron Focusers</td></tr>
                <tr><td><code>0x05</code></td><td>ITEMTYPE_SPEED_BUFF</td>    <td>Infusion P-Coils</td></tr>
                <tr><td><code>0x06</code></td><td>ITEMTYPE_SHIELD_BUFF</td>   <td>Carapaction Coils</td></tr>
                <tr><td><code>0x07</code></td><td>ITEMTYPE_COMM_BUFF</td>     <td>Secret code case / Double agent</td></tr>
              </tbody>
            </table>
          </section>
        </section>

        <section id="packet-structure">
          <h2>Packet Structure</h2>
          <p>
            Artemis packets have two parts: the preamble and the payload.
          </p>
          <section id="packet-structure-preamble">
            <h3>Preamble</h3>
            <p>
              The preamble consists of metadata that describes what kind packet it is and how long
              it is. The information in the preamble is needed in order to interpret the payload.
              The preamble consists of the following parts:
            </p>
            <h4>Header (int)</h4>
            <p>
              The first four bytes constitute a header which identifies the packet as an Artemis
              packet. This value should always be <code>0xdeadbeef</code>.
            </p>
            <h4>Packet length (int)</h4>
            <p>
              Gives the total length of the packet in bytes, including both the preamble and the
              payload.
            </p>
            <h4>Origin (int)</h4>
            <p>
              A <a href="#enum-connection-type">connection type</a> enumeration value indicating
              whether the packet originates from the server or the client.
            </p>
            <h4>Padding (int)</h4>
            <p>
              This value is always <code>0x00</code>.
            </p>
            <h4>Remaining bytes (int)</h4>
            <p>
              The number of bytes following this field in the packet. This is the length of the
              packet type field (4) plus the length of the payload, or the length of the entire
              packet minus 20.
            </p>
            <h4>Packet type (int)</h4>
            <p>
              This value identifies the type of this packet. Refer to the
              <a href="#packet-types">packet types table</a> to find the values that correspond to
              the various packet types. Note that many packets also have a subtype value; for those
              packets, the subtype will be the first value transmitted in the payload.
            </p>
          </section>
          <section id="packet-structure-payload">
            <h3>Payload</h3>
            <p>
              The remaining bytes in the packet after the preamble constitute the payload. Its
              format will vary depending on the packet type. Refer to the next section to see what
              packet types exist and the formats of their payloads.
            </p>
          </section>
        </section>

        <section id="packet-types">
          <h2>Packet Types</h2>
          <p>
            The table below lists the known packet types. The type names are derived from the class
            names for the packets in
            <a href="https://github.com/rjwut/ArtClientLib" target="_new">ArtClientLib</a>.
          </p>
          <table id="packet-table" class="table-striped">
            <thead>
              <tr>
                <th>Name</th>
                <th>Origin</th>
                <th>Type</th>
                <th>Subtype(s)</th>
              </tr>
            </thead>
            <tbody></tbody>
          </table>

          <section id="pkg-hypothetical">
            <h3>Hypothetical</h3>

            <section id="__hypothetical_0x0351a5ac_0x03">
              <h3>__client_hypothetical__1</h3>
              <div class="pkt-props">Type: <code>0x0351a5ac</code>:<code>0x03</code> [from <span>client</span>]</div>
              <p>
                This packet has not been observed, but has been
                hypothesized to exist based on the numeric range of
                the subtype. Nothing concrete is known about this
                packet type at this point, or even if it exists.
              </p>
              <h4>Payload</h4>
              <dl>
                <dt>Subtype (int)</dt>
                <dd>
                  <p>
                    Always <code>0x03</code>.
                  </p>
                </dd>
              </dl>
            </section>


            <section id="__hypothetical__0x69cc01d9_0x01">
              <h3>__client_hypothetical__3</h3>
              <div class="pkt-props">Type: <code>0x69cc01d9</code>:<code>0x01</code> [from <span>client</span>]</div>
              <p>
                This packet has not been observed, but has been
                hypothesized to exist based on the numeric range of
                the subtype. Nothing concrete is known about this
                packet type at this point, or even if it exists.
              </p>
              <h4>Payload</h4>
              <dl>
                <dt>Subtype (int)</dt>
                <dd>
                  <p>
                    Always <code>0x01</code>.
                  </p>
                </dd>
              </dl>
            </section>

            <section id="__hypothetical__0xf754c8fe_0x01">
              <h3>__server_hypothetical__1</h3>
              <div class="pkt-props">Type: <code>0xf754c8fe</code>:<code>0x01</code> [from <span>server</span>]</div>
              <p>
                This packet has not been observed, but has been
                hypothesized to exist based on the numeric range of
                the subtype. Nothing concrete is known about this
                packet type at this point, or even if it exists.
              </p>
              <h4>Payload</h4>
              <dl>
                <dt>Subtype (int)</dt>
                <dd>
                  <p>
                    Always <code>0x01</code>.
                  </p>
                </dd>
              </dl>
            </section>

            <section id="__hypothetical__0xf754c8fe_0x02">
              <h3>__server_hypothetical__2</h3>
              <div class="pkt-props">Type: <code>0xf754c8fe</code>:<code>0x02</code> [from <span>server</span>]</div>
              <p>
                This packet has not been observed, but has been
                hypothesized to exist based on the numeric range of
                the subtype. Nothing concrete is known about this
                packet type at this point, or even if it exists.
              </p>
              <h4>Payload</h4>
              <dl>
                <dt>Subtype (int)</dt>
                <dd>
                  <p>
                    Always <code>0x02</code>.
                  </p>
                </dd>
              </dl>
            </section>

            <section id="__hypothetical__0xf754c8fe_0x0e">
              <h3>__server_hypothetical__2</h3>
              <div class="pkt-props">Type: <code>0xf754c8fe</code>:<code>0x0e</code> [from <span>server</span>]</div>
              <p>
                This packet has not been observed, but has been
                hypothesized to exist based on the numeric range of
                the subtype. Nothing concrete is known about this
                packet type at this point, or even if it exists.
              </p>
              <h4>Payload</h4>
              <dl>
                <dt>Subtype (int)</dt>
                <dd>
                  <p>
                    Always <code>0x0e</code>.
                  </p>
                </dd>
              </dl>
            </section>

            <section id="__hypothetical__0xf754c8fe_0x16">
              <h3>__server_hypothetical__3</h3>
              <div class="pkt-props">Type: <code>0xf754c8fe</code>:<code>0x16</code> [from <span>server</span>]</div>
              <p>
                This packet has not been observed, but has been
                hypothesized to exist based on the numeric range of
                the subtype. Nothing concrete is known about this
                packet type at this point, or even if it exists.
              </p>
              <h4>Payload</h4>
              <dl>
                <dt>Subtype (int)</dt>
                <dd>
                  <p>
                    Always <code>0x16</code>.
                  </p>
                </dd>
              </dl>
            </section>

          </section>

          <section id="pkg-unknown">
            <h3>Unknown</h3>

            <section id="__unknown__0x4c821d3c_0x05">
              <h3>__client_unknown__1</h3>
              <div class="pkt-props">Type: <code>0x4c821d3c</code>:<code>0x05</code> [from <span>client</span>]</div>
              <p>
                This packet type has been observed, and is known to
                exist, but its function is as of yet completely
                unknown. All examples so far have seen was sent from
                Helm to Server.
              </p>
              <h4>Payload</h4>
              <dl>
                <dt>Subtype (int)</dt>
                <dd>
                  <p>
                    Always <code>0x05</code>.
                  </p>
                </dd>
              </dl>
            </section>

            <section id="__unknown__0x4c821d3c_0x06">
              <h3>__client_unknown__2</h3>
              <div class="pkt-props">Type: <code>0x4c821d3c</code>:<code>0x06</code> [from <span>client</span>]</div>
              <p>
                This packet type has been observed, and is known to
                exist, but its function is as of yet completely
                unknown. All examples so far have seen was sent from
                Helm to Server.
              </p>
              <h4>Payload</h4>
              <dl>
                <dt>Subtype (int)</dt>
                <dd>
                  <p>
                    Always <code>0x06</code>.
                  </p>
                </dd>
                <dt>Observed payload</dt>
                <dd>
                  So far, only 0x00000000 (4 bytes) has been observed.
                </dd>
              </dl>
            </section>


            <section id="__unknown__0x4c821d3c_0x17">
              <h3>__client_unknown__3</h3>
              <div class="pkt-props">Type: <code>0x4c821d3c</code>:<code>0x17</code> [from <span>client</span>]</div>
              <p>
                This packet type has been observed, and is known to
                exist, but its function is as of yet completely
                unknown.
              </p>
              <h4>Payload</h4>
              <dl>
                <dt>Subtype (int)</dt>
                <dd>
                  <p>
                    Always <code>0x17</code>.
                  </p>
                </dd>
                <dt>Observed payload</dt>
                <dd>
                  So far, no payload apart from subtype has been observed.
                </dd>
              </dl>
            </section>


            <section id="__unknown__0xf5821226">
              <h3>__server_unknown__1</h3>
              <div class="pkt-props">Type: <code>0xf5821226</code> [from <span>server</span>]</div>
              <p>
                This packet is seen regularly from the server, in
                every game type. It is speculated to be a heartbeat
                packet, that simply serves to ensure the clients that
                the server is still alive and well-connected.
              </p>
              <h4>Payload</h4>
              <p>This packet has no payload.</p>
            </section>

            <section id="__unknown__0xf754c8fe_0x07">
              <h3>__server_unknown__2</h3>
              <div class="pkt-props">Type: <code>0xf754c8fe</code>:<code>0x07</code> [from <span>server</span>]</div>
              <p>
                This packet type has been observed, and its payload
                structure is believed to be understood. However, its
                function has not determined with certainty.

                Contains three floats which seem to correspond to map
                coordinates of ships with special abilities. Could
                relate to cloak/decloak graphical effects.
              </p>
              <h4>Payload</h4>
              <dl>
                <dt>Subtype (int)</dt>
                <dd>
                  <p>
                    Always <code>0x07</code>.
                  </p>
                </dd>
                <dt>x_coordinate (float)</dt>
                <dd>
                  Unknown
                </dd>
                <dt>y_coordinate (float)</dt>
                <dd>
                  Unknown
                </dd>
                <dt>z_coordinate (float)</dt>
                <dd>
                  Unknown
                </dd>
              </dl>
            </section>

            <section id="__unknown__0xf754c8fe_0x08">
              <h3>__server_unknown__3</h3>
              <div class="pkt-props">Type: <code>0xf754c8fe</code>:<code>0x08</code> [from <span>server</span>]</div>
              <p>
                This packet type has been observed, and its payload
                structure is believed to be understood. However, its
                function is as of yet completely unknown. Has been
                hypothesized as having some relation
                to <a href="#soundeffectpacket">SoundEffectPacket</a>.
              </p>
              <h4>Payload</h4>
              <dl>
                <dt>Subtype (int)</dt>
                <dd>
                  <p>
                    Always <code>0x08</code>.
                  </p>
                </dd>
                <dt>Unknown (float)</dt>
                <dd>
                  Values of 0.0, 50.0 and 100.0 has been observed. It
                  is unclear if other values have been observed.
                </dd>
              </dl>
            </section>

            <section id="__unknown__0xf754c8fe_0x13">
              <h3>__server_unknown__4</h3>
              <div class="pkt-props">Type: <code>0xf754c8fe</code>:<code>0x13</code> [from <span>server</span>]</div>
              <p>
                This packet type has been observed, and its payload
                structure is believed to be understood. However, its
                function is as of yet completely unknown.

                Seems to happen immediately before DestroyObject(Mine,
                objID) or DestroyObject(Torpedo, objID).

                Speculated to have some relation to
                detonations.
              </p>
              <h4>Payload</h4>
              <dl>
                <dt>Subtype (int)</dt>
                <dd>
                  <p>
                    Always <code>0x13</code>.
                  </p>
                </dd>
                <dt>Unknown (int)</dt>
                <dd>
                  Only the value 7 has been observed so far. Unknown
                  function or significance.
                </dd>
                <dt>object_id (int)</dt>
                <dd>
                  In the observed packets, the object ids correspond
                  to a mixture of torpedos and mines, destroyed in the
                  very next packet.
                </dd>
              </dl>
            </section>

          </section>

          % for prefix in ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L"]:
${section(prefix)}\
          % endfor
          <section id="pkt-o">
            <h3>O</h3>
            <section id="objectupdatepacket">
              <h3>ObjectUpdatePacket</h3>
              <div class="pkt-props">Type: <code>0x80803df9</code> [from <span>server</span>]</div>
              <p>
                Updates the status of one or more objects in the game
                world. Each type of object update has its own encoding
                within this package, which makes this packet both the
                single most important server packet type, as well as
                the most complicated one to implement.
              </p>
              <p>
                Whereas other packet types that have many subtypes
                (for example, 0x4c821d3c) are documented for each
                subtype, that is not possible for this packet type,
                since it can contain more than one object update type
                in each packet.
              </p>
              <p>
                <em>Note</em>: The official Artemis server always
                seems to send objects of only one type in a single
                packet. If other types of objects need to be updated,
                they'll be transmitted in separate packets. However,
                keep in mind that the protocol does not require this,
                so it might change in the future.
              </p>
              <h4>Payload</h4>
              <p>
                The payload consists of an array of object update
                entries. Parsing continues in a loop until the end of
                the packet is reached, or the object type byte is
                <code>0x00</code>. Note that the array may be empty.
                Each entry in the array is structured as follows:
              </p>
              <dl>
                <dt><a href="#enum-object-type">Object type</a> (byte, enumeration)</dt>
                <dd>
                  <p>
                    The type of object represented by this entry. All objects in the same array will
                    be of the same type. If you get <code>0x00</code> for this field, there are no
                    more objects in the array.
                  </p>
                  <p>
                    In earlier protocol versions, this property was
                    transmitted as an int rather than a byte. At least
                    version 2.1.1 and onwards use the single byte
                    encoding, but it is not verified if version 2.1.1
                    is the first version to do so.
                  </p>
                </dd>
                <dt>Object ID (int)</dt>
                <dd>
                  <p>
                    A unique identifier assigned to this object.
                  </p>
                </dd>
                <dt>Bit field (variable length)</dt>
                <dd>
                  <p>
                    In order to minimize the amount of data that has to be transmitted, the server
                    typically only sends the properties that have changed instead of the entire
                    object every time. This bit field indicates which properties are included in the
                    update. Each bit represents a single property; if a bit is set to
                    <code>1</code>, that property is included. The length of the bit field depends
                    the number of properties the object has.
                  </p>
                </dd>
                <dt>Properties (variable length)</dt>
                <dd>
                  <p>
                    The rest of the entry consists of the updated values for the properties
                    indicated in the bit field.
                  </p>
                </dd>
              </dl>
              <p>
                For details about the properties of the various object types which may be included
                in the array entries, see the
                <a href="#object-properties">Object Properties</a> section.
              </p>
            </section>
          </section>
          % for prefix in ["P", "R", "S", "T", "U", "V", "W"]:
${section(prefix)}\
          % endfor
        </section>

        <section id="object-properties">
          <h2>Object Properties</h2>
          <p>
            This section documents the bit fields and properties for each of the
            <a href="#enum-object-type">object types</a>.
            See
            <a href="#objectupdatepacket">ObjectUpdatePacket</a> for how these objects are updated
            by the Artemis server.
          </p>

          % for obj in objects:
          <section id="object-${camelcase_to_id(obj.name)}">
            <h3>${camelcase_to_name(obj.name)}</h3>
            % if obj.comment:
            <p>
              ${format_comment(obj.comment)}
            </p>
            % endif
            <dl>
            % if obj.name == "PlayerShipUpgrades":
              <dt>Activation flags (bits 1.1-4.4, bool8)</dt>
              % for field in obj.fields[:28]:
              <dd>(bit ${index_to_bit(loop.index + 0)}) ${field.name}</dd>
              % endfor
              <dt>Available upgrades (bits 4.5-7.8, i8)</dt>
              % for field in obj.fields[28:56]:
              <dd>(bit ${index_to_bit(loop.index + 28)}) ${field.name}</dd>
              % endfor
              <dt>Activation time (bits 8.1-11.4, u16)</dt>
              % for field in obj.fields[56:]:
              <dd>(bit ${index_to_bit(loop.index + 56)}) ${field.name}</dd>
              % endfor
            % else:
              % if int(obj.arg) == 1:
              <dt>Bit field (1 byte)</dt>
              % else:
              <dt>Bit field (${obj.arg} bytes)</dt>
              % endif
              % for field in obj.fields:
              <dt>${present_property(field, loop.index)}</dt>
              % if field.comment:
              <dd>
                <p>
                  ${format_comment(field.comment)}
                </p>
              </dd>
              % endif
              % endfor
            % endif
            </dl>
          </section>

          % endfor

        <section id="game-events">
          <h2>Game Events</h2>
          <p>
            Certain in-game events cause the transmission specific patterns of packets. This section
            documents some of these observed patterns:
          </p>
          <section>
            <h3>Connected to server, no simulation running</h3>
            <ol>
              <li><a href="#welcomepacket">WelcomePacket</a></li>
              <li><a href="#versionpacket">VersionPacket</a></li>
              <li><a href="#consolestatuspacket">ConsoleStatusPacket</a></li>
              <li><a href="#allshipsettingspacket">AllShipSettingsPacket</a></li>
            </ol>
          </section>
          <section>
            <h3>Simulation starts while client is connected</h3>
            <ol>
              <li><a href="#skyboxpacket">SkyboxPacket</a></li>
              <li>Unknown packet: type=<code>0xf754c8fe</code> subtype=<code>0x08</code></li>
              <li><a href="#difficultypacket">DifficultyPacket</a></li>
              <li><a href="#allshipsettingspacket">AllShipSettingsPacket</a></li>
            </ol>
          </section>
          <section>
            <h3>Client clicks "Ready" while simulation is already running</h3>
            <ol>
              <li><a href="#pausepacket">PausePacket</a></li>
              <li><a href="#skyboxpacket">SkyboxPacket</a></li>
              <li><a href="#difficultypacket">DifficultyPacket</a></li>
              <li><a href="#allshipsettingspacket">AllShipSettingsPacket</a></li>
              <li><a href="#keycapturetogglepacket">KeyCaptureTogglePacket</a></li>
            </ol>
          </section>
          <section>
            <h3>Fighter is launched</h3>
            <ol>
              <li><a href="#fighterlaunchpacket">FighterLaunchPacket</a></li>
              <li><a href="#fighterlaunchedpacket">FighterLaunchedPacket</a></li>
              <li><a href="#fighterbaystatuspacket">FighterBayStatusPacket</a> (informing that the fighter is no longer in the bay)</li>
              <li><a href="#objectupdatepacket">ObjectUpdatePacket</a> (fighters are now updated as separate ship objects)</li>
            </ol>
          </section>
          <section>
            <h3>Fighter is docked</h3>
            <ol>
              <li><a href="#helmrequestdockpacket">HelmRequestDockPacket</a> (sent by the fighter)</li>
              <li><a href="#destroyobjectpacket">DestroyObjectPacket</a> (destroys the fighter's ship object)</li>
              <li><a href="#fighterbaystatuspacket">FighterBayStatusPacket</a> (informating that the fighter is now in the bay)</li>
              <li><a href="#objectupdatepacket">ObjectUpdatePacket</a> (the docked fighter is no longer a separate ship object)</li>
            </ol>
          </section>
        </section>

        <section id="ship-internals">
          <h2>Ship Internals</h2>
          <p>
            The layout of system nodes in a vessel is stored in an .snt file referenced by the
            vessel's entry in vesselData.xml. This section documents the file format used by these
            files.
          </p>
          <p>
            A vessel's internal system grid is laid out in a 5 &times; 5 &times; 10 matrix: X (port
            to starboard), Y (dorsal to ventral), then Z (fore to aft). An .snt file contains 250
            blocks of data, with each block representing one node in the system grid. The nodes are
            iterated first in the X axis, then Y, then Z. So the first ten nodes are (0,0,0) through
            (0,0,9), followed by (0,1,0) through (0,1,9), etc.
          </p>
          <p>
            Each block is 32 bytes long. The first 12 bytes contain the node's position in the
            vessel's 3D coordinate system. (This is separate from its system grid coordinates.) The
            coordinates are stored as three floats: X, Y, then Z.
          </p>
          <p>
            Next is an int value which describes what kind of node it is. A value from 0 to 7
            indicates that the node contains vital equipment for one of the ship systems; you can
            tell which system by looking up the corresponding value in the
            <a href="#enum-ship-system">ship system enumeration</a>. A value of -1 indicates a
            hallway; it contains no ship systems but is still accessible to DAMCON teams. A value of
            -2 indicates an empty node; it contains no ship systems and is not accessible to DAMCON
            teams. This is typically for nodes that would fall outside the vessel's hull.
          </p>
          <p>
            The remaining 16 bytes in the block appear to be reserved for future use.
          </p>
        </section>
      </content>
    </div>
  </body>
</html>
