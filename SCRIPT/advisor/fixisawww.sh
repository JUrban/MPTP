for i in `ls [A-Z]*.html`; do sed -ie 's/^<body/<body onload=findString1()/; s/^\(<link.*\)/\1<script \
type="text\/javascript" src="find.js"><\/script>/' $i; done
