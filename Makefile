diff:
	@transwarp -D isolinear-chips/protocol

gen:
	@transwarp -D isolinear-chips/protocol -u

clean:
	@find . -type f -name '*~' -delete
