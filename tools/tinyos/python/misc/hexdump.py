def b2str(byts):
    ''' b2str: bytes to string
        convert a sequence of bytes to its equivilent string.  Straight across
        conversion.
    '''

    assert type(byts)==bytes, 'b2str: byts parmeter is of wrong type'
    s = ''.join([chr(x) for x in byts])
    return s


def b2str_dots(byts):
    ''' b2str: bytes to string
        convert a sequence of bytes to its equivilent string.  non-ascii chars are
        simply set to '.'.    This avoids decoding exceptions from unicode.
    '''

    assert type(byts)==bytes, 'b2str: byts parmeter is of wrong type'
    s = ''.join([((((x < 32) or (x > 0x7e)) and '.') or chr(x)) for x in byts])
    return s


def hd(byts, length=16):
    ''' hd: hexdump
        dump in hex with pretty formating the hex value and ascii value (if any)
        for a block of bytes [assumed to be a tuple]

        byts:   incoming bytes
        length: how many bytes to display on each line.
    '''

    assert type(byts)==bytes, 'hd: byts parmeter is of wrong type'
    n=0; result=''
    while byts:
       b_work, byts = byts[:length], byts[length:]
       hexa = ' '.join(["%02X"%x for x in b_work])
       asc  = ''.join([((((x < 32) or (x > 0x7e)) and '.') or chr(x)) for x in b_work])
       result += "%04X   %-*s   %s\n" % (n, length*3, hexa, asc)
       n += length
    return result

#def main():
#    s=("This 10 line function is just a sample of python's power "
#       "for string manipulations.\n"
#       "The code is \x07even\x08 quite readable!")
#    print(hd(s.encode()))
#
#    s=bytes.fromhex('0001020304057e7f 353637384042  80999d9e9fa0a1aeaf ded0dfc0cfe0f0ff')
#    print(hd(s))
#
#    print(b2str(s))
#    print(b2str_dots(s))
#
#if __name__ == '__main__':
#  main()
#
