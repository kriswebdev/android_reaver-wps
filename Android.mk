# (c) 2014 KrisWebDev
# License: This file (solely) is licenced under the GNU GPL v2
# > Put sources in external/<module-name> folder in CM source root

LOCAL_PATH:=$(call my-dir)



# GENERAL
MY_CFLAGS	:= -g -Wall -W -O3 -Wno-unused-but-set-variable -Wno-array-bounds -DANDROID
MY_C_INCLUDES	:= $(LOCAL_PATH)/common $(LOCAL_PATH)/crypto $(LOCAL_PATH)/libwps $(LOCAL_PATH)/lwe $(LOCAL_PATH)/tls $(LOCAL_PATH)/utils
MY_SHARED_LIBS	:= libsqlite
# error: libpcap compiles well but crashes the executable with "syntax error" / "syntax error: unknown ID" (libpcap debug CFLAGS: -DYYDEBUG -DYYERROR_VERBOSE)
# solution: update libpcap to 1.5.2+
# error: some libpcap headers missing for libpcap 1.5.2+
# solution: use kernel headers... Copy linux/types.h and all linux/netfilter/netfilter*.h headers in a separate include folder. Comment "#define HAVE_LINUX_NET_TSTAMP_H 1" in config.h.
MY_STATIC_LIBS	:= libpcap
MY_C_INCLUDES	+= external/libpcap external/openssl/include external/sqlite/dist

# CONF
# MY_CONFDIR	:= "/etc/reaver"

# DEPENDENCY: libwps
MY_SRC_LIBWPS	:= libwps/libwps.c

# DEPENDENCY: wps
MY_SRC_WPS	:= wps/wps_attr_build.c wps/wps_attr_parse.c wps/wps_attr_process.c wps/wps.c wps/wps_common.c wps/wps_dev_attr.c wps/wps_enrollee.c wps/wps_registrar.c wps/wps_ufd.c

# DEPENDENCY: libcrypto
# error: libcrypto from external/openssl won't work
# solution: use libcrypto provided with the source
# error: crypto/md5-non-fips.o: multiple definition of 'hmac_md5_vector'
# solution: rewrite md5.h as if CONFIG_FIPS=true
MY_CFLAGS	+= -DCONFIG_TLS_INTERNAL_CLIENT -DCONFIG_TLS_INTERNAL_SERVER
MY_SRC_CRYPTO	:= crypto/aes-cbc.c crypto/aes-ctr.c crypto/aes-eax.c crypto/aes-encblock.c crypto/aes-internal.c crypto/aes-internal-dec.c crypto/aes-internal-enc.c crypto/aes-omac1.c crypto/aes-unwrap.c crypto/aes-wrap.c crypto/des-internal.c crypto/dh_group5.c crypto/dh_groups.c crypto/md4-internal.c crypto/md5.c crypto/md5-internal.c crypto/md5-non-fips.c crypto/milenage.c crypto/ms_funcs.c crypto/rc4.c crypto/sha1.c crypto/sha1-internal.c crypto/sha1-pbkdf2.c crypto/sha1-tlsprf.c crypto/sha1-tprf.c crypto/sha256.c crypto/sha256-internal.c crypto/crypto_internal.c crypto/crypto_internal-cipher.c crypto/crypto_internal-modexp.c crypto/crypto_internal-rsa.c crypto/tls_internal.c crypto/fips_prf_internal.c

# DEPENDENCY: lwe
#WT_VERSION	:= $(shell sed -ne "/WT_VERSION/{s:\([^0-9]*\)::;p;q;}" < lwe/iwlib.h )
#WE_VERSION	:= $(shell sed -ne "/WE_VERSION/{s:\([^0-9]*\)::;p;q;}" < lwe/iwlib.h )
#WEXT_HEADER	:= lwe/wireless.$(WE_VERSION).h
# Cross-compilation, manual copy required: cp wireless.21.h wireless.h
MY_SRC_LWE	:= lwe/iwlib.c
# These seem to be useless:
#lwe/iwconfig.c lwe/iwlist.c lwe/iwpriv.c lwe/iwspy.c lwe/iwgetid.c lwe/iwevent.c lwe/ifrename.c
#alternative: -DWE_NOLIBM=y
MY_STATIC_LIBS	+= libm
MY_C_INCLUDES	+= bionic/libm/include bionic/libm
# removed: -Os  -I. -MMD (shared library thing) -fPIC (shared library thing, position-independant code), -Wl,-s for iwmulticall, -Wstrict-prototypes   (annoyong other code)-Wmissing-prototypes  (annoyong other code)
MY_CFLAGS	+= -Wshadow -Wpointer-arith -Wcast-qual -Winline
# /etc/reaver doesn't exist in Android and we should avoid writing in such dirs anyway
# MY_CFLAGS	+= -DCONF_DIR='"/etc/reaver"' -DREAVER_DATABASE='"/etc/reaver/reaver.db"'
# $(MY_CONFDIR)

# DEPENDENCY: tls
MY_CFLAGS	+= -DCONFIG_INTERNAL_LIBTOMMATH -DCONFIG_CRYPTO_INTERNAL
MY_SRC_TLS	:= tls/asn1.c tls/bignum.c tls/pkcs1.c tls/pkcs5.c tls/pkcs8.c tls/rsa.c tls/tlsv1_client.c tls/tlsv1_client_read.c tls/tlsv1_client_write.c tls/tlsv1_common.c tls/tlsv1_cred.c tls/tlsv1_record.c tls/tlsv1_server.c tls/tlsv1_server_read.c tls/tlsv1_server_write.c tls/x509v3.c

# DEPENDENCY: utils
MY_CFLAGS	+= -DCONFIG_IPV6
MY_SRC_UTILS	:= utils/base64.c utils/common.c utils/ip_addr.c utils/radiotap.c utils/trace.c utils/uuid.c utils/wpa_debug.c utils/wpabuf.c utils/os_unix.c utils/eloop.c


# MAIN EXECUTABLES
# error: wpsmon.c:321: error: undefined reference to 'ualarm'
# solution: there's no ucall() in bionic (Android libc) => rewritten wpsmon.c to use create_timer() instead.
MY_SRC_REAVER	:= $(MY_SRC_TLS) $(MY_SRC_CRYPTO) $(MY_SRC_WPS) $(MY_SRC_LIBWPS) $(MY_SRC_UTILS) \
	argsparser.c globule.c init.c sigint.c sigalrm.c misc.c cracker.c keys.c pins.c iface.c send.c exchange.c session.c sql.c builder.c crc.c 80211.c wpscrack.c
MY_CFLAGS	+= -DNO_UALARM
# error: empty list of networks in wash
# debug: implement --debug command line flag: see the list of networks even if SQL fails and logcat of sql.c's sql_exec() error code - requires liblog and -DANDROID CFLAG
# solution: change default database (& config) dir to working dir, make the database dir configurable from command line argument
MY_SRC_WASH	:= $(MY_SRC_TLS) $(MY_SRC_CRYPTO) $(MY_SRC_WPS) $(MY_SRC_LIBWPS) $(MY_SRC_UTILS) \
	argsparser.c globule.c init.c misc.c iface.c sql.c builder.c crc.c 80211.c wpsmon.c 



#> GCC flags help:
# -g:	 Produce debugging information
# -W:	 (-Wextra) This enables some extra warning flags that are not enabled by -Wall, inc. -Wunused-parameter.
# -O3:	 The compiler tries to reduce code size and execution time. Optimize yet more with -O3.
# -Wall: Turns on the warning flags
# -Wno-unused-but-set-variable:	Don't warn whenever a local variable is assigned to, but otherwise unused (aside from its declaration).
# -Wno-array-bounds:		Don't warn whenever subscripts to arrays that are always out of bounds. This option is only active when -ftree-vrp is active (default for -O2 and above).
# -Idir:	 Add the directory dir to the head of the list of directories to be searched for header files. 
# -D name=definition: The contents of definition are tokenized and processed as if they appeared during translation phase three in a ‘#define’ directive.
#
#> Unused:
# -c: Compile or assemble the source files, but do not link.
# -s: Strip the debug information, so as to make the code as small as possible.


include $(CLEAR_VARS)
LOCAL_MODULE		:= libiwlib
LOCAL_SRC_FILES		:= $(MY_SRC_LWE)
LOCAL_CFLAGS		+= $(MY_CFLAGS)
LOCAL_C_INCLUDES	:= $(MY_C_INCLUDES)
LOCAL_STATIC_LIBRARIES  := $(MY_STATIC_LIBS)
LOCAL_SHARED_LIBRARIES  := $(MY_SHARED_LIBS)
include $(BUILD_STATIC_LIBRARY)

include $(CLEAR_VARS)
LOCAL_MODULE		:= reaver
LOCAL_SRC_FILES		:= $(MY_SRC_REAVER)
LOCAL_CFLAGS		+= $(MY_CFLAGS)
LOCAL_C_INCLUDES	:= $(MY_C_INCLUDES)
LOCAL_STATIC_LIBRARIES  := $(MY_STATIC_LIBS) libiwlib liblog
LOCAL_SHARED_LIBRARIES  := $(MY_SHARED_LIBS)
LOCAL_LDLIBS		:= -llog
include $(BUILD_EXECUTABLE)

include $(CLEAR_VARS)
LOCAL_MODULE		:= reaver-wash
LOCAL_SRC_FILES		:= $(MY_SRC_WASH)
LOCAL_CFLAGS		+= $(MY_CFLAGS)
LOCAL_C_INCLUDES	:= $(MY_C_INCLUDES)
LOCAL_STATIC_LIBRARIES  := $(MY_STATIC_LIBS) libiwlib liblog
LOCAL_SHARED_LIBRARIES  := $(MY_SHARED_LIBS)
#LOCAL_LDLIBS		:= -llog
include $(BUILD_EXECUTABLE)

