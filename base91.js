(function() {
  var AVERAGE_ENCODING_RATIO = 1.2297,
      ENCODING_TABLE = [
        'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N',
        'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
        'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n',
        'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
        '!', '#', '$', '%', '&', '(', ')', '*', '+', ',', '.', '/', ':', ';',
        '<', '=', '>', '?', '@', '[', ']', '^', '_', '`', '{', '|', '}', '~',
        '"'
      ],
      DECODING_TABLE = [
        91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91,
        91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91,
        91, 62, 90, 63, 64, 65, 66, 91, 67, 68, 69, 70, 71, 91, 72, 73,
        52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 74, 75, 76, 77, 78, 79,
        80,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14,
        15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 81, 91, 82, 83, 84,
        85, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
        41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 86, 87, 88, 89, 91,
        91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91,
        91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91,
        91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91,
        91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91,
        91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91,
        91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91,
        91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91,
        91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91, 91
      ];

  var i = 0;

  var base91 = {
    encode: function(data) {
      var len = data.length,
          output = '', ebq = 0, en = 0, ev = 0, j = 0, byte = 0;

      if (typeof data === 'string') {
        for (i = 0; i < len; ++i) {
          byte = data.charCodeAt(i);
          j = 0;
          var lenj = (byte < 128
                      ? 1
                      : (byte > 127 && byte < 2048
                         ? 2
                         : 3));
          for (; j < lenj; ++j) {
            if (lenj === 1)
              ebq |= byte << en;
            else if (lenj === 2) {
              if (j === 0)
                ebq |= ((byte >> 6) | 192) << en;
              else
                ebq |= ((byte & 63) | 128) << en;
            } else {
              if (j === 0)
                ebq |= ((byte >> 12) | 224) << en;
              else if (j === 1)
                ebq |= (((byte >> 6) & 63) | 128) << en;
              else
                ebq |= ((byte & 63) | 128) << en;
            }
            en += 8;
            if (en > 13) {
              ev = ebq & 8191;
              if (ev > 88) {
                ebq >>= 13;
                en -= 13;
              } else {
                ev = ebq & 16383;
                ebq >>= 14;
                en -= 14;
              }
              output += ENCODING_TABLE[ev % 91];
              output += ENCODING_TABLE[(ev / 91) | 0];
            }
          }
        }
      } else {
        for (i = 0; i < len; ++i) {
          ebq |= (data[i] & 255) << en;
          en += 8;
          if (en > 13) {
            ev = ebq & 8191;
            if (ev > 88) {
              ebq >>= 13;
              en -= 13;
            } else {
              ev = ebq & 16383;
              ebq >>= 14;
              en -= 14;
            }
            output += ENCODING_TABLE[ev % 91];
            output += ENCODING_TABLE[(ev / 91) | 0];
          }
        }
      }

      if (en > 0) {
        output += ENCODING_TABLE[ebq % 91];
        if (en > 7 || ebq > 90)
          output += ENCODING_TABLE[(ebq / 91) | 0];
      }

      return output;
    },
    decode: function(data) {
      var len = data.length,
          estimatedSize = ((len / AVERAGE_ENCODING_RATIO) | 0),
          dbq = 0, dn = 0, dv = -1, i = 0, o = -1, byte = 0,
          output = new Array(estimatedSize);

      if (typeof data === 'string') {
        for (i = 0; i < len; ++i) {
          byte = data.charCodeAt(i);
          if (DECODING_TABLE[byte] === 91)
            continue;
          if (dv === -1)
            dv = DECODING_TABLE[byte];
          else {
            dv += DECODING_TABLE[byte] * 91;
            dbq |= dv << dn;
            dn += ((dv & 8191) > 88 ? 13 : 14);
            do {
              if (++o >= estimatedSize)
                output.push(dbq & 0xFF);
              else
                output[o] = dbq & 0xFF;
              dbq >>= 8;
              dn -= 8;
            } while (dn > 7);
            dv = -1;
          }
        }
      } else {
        for (i = 0; i < len; ++i) {
          byte = data[i];
          if (DECODING_TABLE[byte] === 91)
            continue;
          if (dv === -1)
            dv = DECODING_TABLE[byte];
          else {
            dv += DECODING_TABLE[byte] * 91;
            dbq |= dv << dn;
            dn += ((dv & 8191) > 88 ? 13 : 14);
            do {
              if (++o >= estimatedSize)
                output.push(dbq & 0xFF);
              else
                output[o] = dbq & 0xFF;
              dbq >>= 8;
              dn -= 8;
            } while (dn > 7);
            dv = -1;
          }
        }
      }

      if (dv !== -1) {
        if (++o >= estimatedSize)
          output.push(dbq | dv << dn);
        else
          output[o] = (dbq | dv << dn);
      }

      if (o > -1 && o < estimatedSize - 1)
        output = output.slice(0, o + 1);

      return new Buffer(output);
    }
  };

  module.exports = base91;
})();
