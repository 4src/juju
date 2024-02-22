BEGIN {b4="#"}
/#!.usr.bin.env/ { next}
{if (sub(/^#[ ]?/,"")) {
  if (b4=="#") 
    print
  else {
    print "```\n"
    print
  }
  b4="#"
} else { 
  if (b4=="#") {
    print "\n```julia"  
    print 
  } else {
    print
  }
  b4="" 
}}
END {if (last !="#") print "```"}