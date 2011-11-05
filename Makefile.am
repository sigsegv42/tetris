AUTOMAKE_OPTIONS = subdir-objects
ACLOCAL_AMFLAGS = ${ACLOCAL_FLAGS} -I .

SUBDIRS = \
tetris \
tests

gcov_sources = $(unit_tests_SOURCES)

if GCOV_ENABLED
gcov-report.txt: gcov-clean
	$(QUIET_GEN)(rm -f $@; \
	echo -e "Test coverage for v3D:\n" >> $@; \
	total_covered=0; total_actual=0; \
	for file in $(filter %.cxx,$(gcov_sources)); do \
		gcov -o .libs/$${file/.c/.gcda} $$file > /dev/null; \
		if test -f $$file.gcov; then \
			actual=`grep -v ' -:' $$file.gcov | wc -l`; \
			uncovered=`grep '#####:' $$file.gcov | wc -l`; \
			covered=$$((actual - uncovered)); \
			total_covered=$$((total_covered + covered)); \
			total_actual=$$((total_actual + actual)); \
			echo -e "$$file:    \t$$covered / $$actual\t($$((($$covered * 100) / $$actual))%)"; \
		fi \
	done >> $@; \
	cd $(abs_srcdir); \
	echo -e "\nSource lines: $$total_actual\nCovered statements: $$total_covered\nTotal coverage: $$((($$total_covered * 100) / $$total_actual))%" >> $@)

gcov: gcov-report.txt
	@echo ""; cat gcov-report.txt
cov:
	@make gcov-report
gcov-report:
	@mkdir -p coverage
	@lcov --compat-libtool --directory . --capture --output-file coverage/app.info
	@lcov --extract coverage/app.info *tetris/* --output-file coverage/local.info
	@genhtml -o coverage/ coverage/local.info 
gcov-reset:
	@rm -fr coverage
	@find . -name "*.gcda" -exec rm {} \;
	@lcov --directory . --zerocounters
gcov-clean:
	@find . -name "*.gcda" -o -name "*.gcov" -delete
clean-local:
	@make gcov-reset 
check:
	@make test
	@make cov
else
gcov-report.txt:
	@true
cov-reset:
	@true
gcov-clean:
	@true
cov:
	@echo "Code coverage not enabled"
gcov:
	@echo "Need to reconfigure with --enable-gcov"
endif	# GCOV_ENABLED


test:
	@sh ./run-unit-tests.sh


.PHONY: gcov gcov-clean gcov-report.txt
