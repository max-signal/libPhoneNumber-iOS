.PHONY: metadata
metadata:
	swift run --package-path MetadataArchiver -c release MetadataArchiver ${LIBPHONENUMBER}
