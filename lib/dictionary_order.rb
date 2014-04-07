# encoding: utf-8

# This module implements a function, normalize, which is used to
# normalize and put to lowercase the names in the _d fields, ex. full_name_d in People
# The non-ascii chars are mapped to ASCII using the MAP table.
module DictionaryOrder
  MAP = {  
    [
      'À',    #Capital A, grave accent ("&Agrave;")
      'Á',    #Capital A, acute accent ("&Aacute;")
      'Â',    #Capital A, circumflex accent ("&Acirc;")
      'Ã',    #Capital A, tilde ("&Atilde;")
      'Å',    #Capital A, ring ("&Aring;") 
      'à',    #Small a, grave accent ("&agrave;")
      'á',    #Small a, acute accent ("&aacute;")
      'â',    #Small a, circumflex accent ("&acirc;")
      'ã',    #Small a, tilde ("&atilde;")
      'ä',    #Small a, dieresis or umlaut mark ("&auml;")
      'å',    #Small a, ring ("&aring;") 
      'ǎ',    #Small a, caron ("&acaron;")
      'ā',    #Small a, macron (?)
      'ą'     #Small a, ogonek ("&aogon;")
    ] => 'a',

    [
      'Æ',    #Capital AE dipthong (ligature) ("&AElig;")
      'æ'     #Small ae dipthong (ligature) ("&aelig;")
    ] => 'ae',
    
    [
      'Ç',    #Capital C, cedilla ("&Ccedil;")
      'Č',    #Capital C, caron ("&Ccaron;")
      'Ć',    #Capital C, acute ("&Cacute;")
      'Ĉ',    #Capital C, circumflex ("&Ccirc;")
      'ç',    #Small c, cedilla ("&ccedil;")
      'ĉ',    #Small c, circumflex ("&ccirc;")
      'č',    #Small c, caron ("&ccaron;")
      'ć'     #Small c, acute accent ("&cacute;")
    ] => 'c',
    
    [
      
      'Ď',    #Capital D, caron ("&Dcaron;")
      'Đ',    #Capital D, african D (?)
      'Ḍ',    #Capital D, dot below (?)
      'Ḓ',    #Capital D, circumflex below (?)
      'ƌ',    #Capital D [sic]?, top bar (?)
      'ḍ',    #Small d, dot below (?) 
      'đ',    #Small d, stroke ("&dstrok;")
      'ḓ'     #Small d, circumflex below (?)
    ] => 'd',
    
    [
      'È',    #Capital E, grave accent ("&Egrave;")
      'É',    #Capital E, acute accent ("&Eacute;")
      'Ê',    #Capital E, circumflex accent ("&Ecirc;")
      'Ë',    #Capital E, dieresis or umlaut mark ("&Euml;")
      'Ě',    #Capital E, caron ("&Ecaron;")
      'Ĕ',    #Capital E, breve ("&Ebreve;")
      'è',    #Small e, grave accent ("&egrave;")
      'é',    #Small e, acute accent ("&eacute;")
      'ê',    #Small e, circumflex accent ("&ecirc;")
      'ë',    #Small e, dieresis or umlaut mark ("&euml;")
      'ě',    #Small e, caron ("&ecaron;")
      'ẽ',    #Small e, tilde ("&etilde;")
      'ē',    #Small e, macron (?)
      'ę',    #Small e, ogonek ("&eogon;")
      'ĕ',    #Small e, breve ("&ebreve;")
      'ė'     #Small e, dot ("&edot;")
    ] => 'e',
    
    [
      'Ḥ',    #Capital H, dot below (?)
      'Ḫ',    #Capital H, breve below (?)
      'ḥ',    #Small h, dot below (?)
      'ḫ'     #Small h, breve below (?)
    ] => 'h',

    [
      'Ì',    #Capital I, grave accent ("&Igrave;")
      'Í',    #Capital I, acute accent ("&Iacute;")
      'Î',    #Capital I, circumflex accent ("&Icirc;")
      'Ï',    #Capital I, dieresis or umlaut mark ("&Iuml;")
      'ì',    #Small i, grave accent ("&igrave;")
      'í',    #Small i, acute accent ("&iacute;")
      'î',    #Small i, circumflex accent ("&icirc;")
      'ï',    #Small i, dieresis or umlaut mark ("&iuml;")
      'ĩ',    #Small i, tilde ("&itilde;")
      'ī'     #Small i, macron (?)
    ] => 'i',
    
    [
      'Ĺ',    #Capital L, acute ("&Lacute;")
      'Ł',    #Capital L, stroke ("&Lstrok;")
      'ĺ',    #Small l, acute ("&lacute;")
      'ł'     #Small l, stroke ("&lstrok;")
    ] => 'l',
  
    [
      'Ń',    #Capital N, acute ("&Nacute;")      
      'Ñ',    #Capital N, tilde ("&Ntilde;")
      'Ň',    #Capital N, caron ("&Ncaron;")
      'ń',    #Small n, acute  ("&nacute;")
      'ǹ',    #Small n, grave ("&ngrave;")
      'ñ',    #Small n, tilde ("&ntilde;")
      'ň'     #Small n, caron ("&ncaron;")
    ] => 'n',
  
    [
      'Ò',    #Capital O, grave accent ("&Ograve;")
      'Ó',    #Capital O, acute accent ("&Oacute;")
      'Ô',    #Capital O, circumflex accent ("&Ocirc;")
      'Õ',    #Capital O, tilde ("&Otilde;")
      'Ö',    #Capital O, dieresis or umlaut mark ("&Ouml;")
      'Ø',    #Capital O, slash ("&Oslash;")
      'Ő',    #Capital O, double acute (?)
      'Ō',    #Capital O, macron (?)
      'ò',    #Small o, grave accent ("&ograve;")
      'ó',    #Small o, acute accent ("&oacute;")
      'ô',    #Small o, circumflex accent ("&ocirc;")
      'õ',    #Small o, tilde ("&otilde;")
      'ö',    #Small o, dieresis or umlaut mark ("&ouml;")
      'ø',    #Small o, slash ("&oslash;")
      'ő',    #Small o, double acute (?)
      'ǒ',    #Small o, caron ("&ocaron;")
      'ō'
    ] => 'o',
    
    [
      'Œ',    #Capital OE dipthong (ligature) ("&OElig;")
      'œ'     #Small oe dipthong (ligature) ("&oelig;")
    ] => 'oe',
    
    [
      'Ŕ',    #Capital R, acute ("&Racute;")
      'Ř',    #Capital R, caron ("&Rcaron;")
      'ŕ',    #Small r, acute ("&racute;")
      'ř'     #Small r, caron ("&rcaron;")
    ] => 'r',

    [ 
      'Ś',    #Capital S, acute ("&Sacute;")
      'Š',    #Capital S, caron ("&Scaron;")
      'Ṣ',    #Capital S, dot below (?)
      'ś',    #Small s, acute ("&sacute;")
      'š',    #Small s, caron ("&scaron;")
      'ş',    #Small s, ogonke ("&sogon;")
      'ṣ'     #Small s, dot below (?)
    ] => 's',  
  
    [ 
      'Ṭ',    #Capital T, dot below (?)
      'Ť',    #Capital T, caron ("&Tcaron;")
      'Ţ',    #Capital T, cedilla ("&Tcedil;")
      'ţ',    #Small t, cedilla ("&tcedil;") 
      'ṭ'     #Small t, dot below (?)
    ] => 't',
    
    [  
      'ß'     #Small sharp s, German (sz ligature) ("&szlig;")
    ] => 'ss',  
  
    [
      'Þ',    #Capital thorn, Icelandic ("&THORN;")
      'þ',    #Small thorn, Icelandic ("&thorn;")
      'ð',    #Small eth, Icelandic ("&eth;")
      'Ð'     #Capital Eth, Icelandic ("&ETH;")
    ] => 'th',  
  
    [
      'Ù',    #Capital U, grave accent ("&Ugrave;")
      'Ú',    #Capital U, acute accent ("&Uacute;")
      'Û',    #Capital U, circumflex accent ("&Ucirc;")
      'Ü',    #Capital U, dieresis or umlaut mark ("&Uuml;")
      'Ű',    #Capital U, double acute (?)
      'Ų',    #Capital U, ogonek ("&Uogon;")
      'Ů',    #Capital U, ring ("&Uring;")
      'Ū',    #Capital U, macron (?)
      'ù',    #Small u, grave accent ("&ugrave;")
      'ú',    #Small u, acute accent ("&uacute;")
      'û',    #Small u, circumflex accent ("&ucirc;")
      'ü',    #Small u, dieresis or umlaut mark ("&uuml;")
      'ǔ',    #Small u, caron ("&ucaron;") 
      'ũ',    #Smalu u, tilda  ("&utilde;")
      'ū',    #Small u, macron (?)
      'ů',    #Small u, ring ("&uring;")
      'ų',    #Small u, ogonek ("&uogon;")
      'ű'     #Small u, double acute (?)
    ] => 'u',  
  
    [  
      'Ý',    #Capital Y, acute accent ("&Yacute;")
      'ý',    #Small y, acute accent ("&yacute;")
      'ÿ'     #Small y, dieresis or umlaut mark ("&yuml;")
    ] => 'y',
    
    [
      'Ź',    #Capital Z, acute ("&Zacute;")
      'Ž',    #Capital Z, caron ("&Zcaron;")
      'Ż',    #Capital Z, dot above ("&Zdot;")
      'Ẓ',    #Capital Z, dot below (?)
      'ź',    #Small z, acute ("&zacute;")
      'ž',    #Small z, caron ("&zcaron;")
      'ż',    #Small z, dot above ("&zdot;")
      'ẓ'     #Small z, dot below (?)
    ] => 'z'
  }   

  # Normalize a string, go downcase and convert all chars to ASCII
  def self.normalize(src)
    new_str = src.downcase
    new_str.gsub!('\'', '')
    MAP.each do |ac,rep|
      ac.each do |s|
        new_str.gsub!(s, rep)
      end
    end
    return new_str
  end
  
end