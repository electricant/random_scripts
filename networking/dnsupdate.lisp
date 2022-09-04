;;
;; Lisp program to update DNS records using nsupdate
;;
;; It checks the current public facing IP against the old saved one. If the two
;; differ a record update is sent.
;;

;; Target DNS server for updates
(defparameter *DNS-server* "ns1.scaramuzza.me")

;; zone
(defparameter *DNS-zone* "scaramuzza.me")

;; domain (with a dot at the end)
(defparameter *domain* "go.scaramuzza.me.")

;; Key file for nsupdate (full path)
(defparameter *key-file* "/root/dnssec/Kbig-gnu.+157+05954.private")

;; command used to retrieve current IP
;; see:
;;	http://unix.stackexchange.com/questions/22615/how-can-i-get-my-external-ip-address-in-bash
;;	http://askubuntu.com/questions/95910/command-for-determining-my-public-ip/427092#427092
(defparameter *IP-cmd* "dig +short myip.opendns.com @resolver1.opendns.com")

;; File holding the last saved IP
(defparameter *IP-file* "/tmp/lastip")

; Function that returns the current ip
(defun get-current-ip ()
	(read-line (run-shell-command *IP-cmd* :output :stream)))

;; Function that returns the last saved ip
(defun get-saved-ip ()
	(with-open-file (inf *IP-file* :if-does-not-exist nil)
		(when inf (read-line inf nil))))

;; Function to send the update request to the server
(defun update-dns (ip)
	(let ((cmdin (format nil "server ~a~%~
	                          zone ~a~%~
	                          update delete ~a A ~%~
	                          update add ~a 60 A ~a~%~
	                          show~%send~%quit~%"
					  *DNS-server*
					  *DNS-zone*
					  *domain*
					  *domain*
					  ip))
	      (cmdstream (run-shell-command
			(format nil "nsupdate -k ~a" *key-file*) :input :stream)))
		(format cmdstream "~a" cmdin)
		(force-output cmdstream))
	;; save ip
	(with-open-file
		(outf *IP-file* :direction :output :if-exists :supersede)
		(write-line ip outf)))

;; Main
(let ((curip (get-current-ip))
      (oldip (get-saved-ip)))
	;; Output a timestamp for logging purposes
	(multiple-value-bind
			(second minute hour date month year day-of-week dst-p tz)
			(get-decoded-time)
		(format t "# ~2,'0d:~2,'0d:~2,'0d, ~d/~2,'0d/~d (GMT~@d)~%"
			hour
			minute
			second
			month
			date
			year
			(- tz)))

	(format T " Saved IP address: ~a~%" oldip)
	(format T " Current IP address: ~a~%" curip)
	(unless (equal curip oldip)
		(update-dns curip)
		(princ " DNS record updated.")))
