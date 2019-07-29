/* customized from claws mail source code */

/* pkcs5_pbkdf2.c - Password-Based Key Derivation Function 2
 * Copyright (c) 2008 Damien Bergamini <damien.bergamini@free.fr>
 *
 * Modifications for Claws Mail are:
 * Copyright (c) 2016 the Claws Mail team
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */
 /*
 * Claws Mail -- a GTK+ based, lightweight, and fast e-mail client
 * Copyright (C) 2016 The Claws Mail Team
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 */



#include <glib.h>
#include <sys/types.h>

#include <string.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>

#define CHECKSUM_BLOCKLEN 64
/*
 * HMAC-SHA-1 (from RFC 2202).
 */
static void
hmac_sha1(const guchar *text, size_t text_len, const guchar *key,
    size_t key_len, guchar *digest)
{
	GChecksum *cksum;
	gssize digestlen = g_checksum_type_get_length(G_CHECKSUM_SHA1);
	gsize outlen;
	guchar k_pad[CHECKSUM_BLOCKLEN];
	guchar tk[digestlen];
	gint i;

	if (key_len > CHECKSUM_BLOCKLEN) {
		cksum = g_checksum_new(G_CHECKSUM_SHA1);
		g_checksum_update(cksum, key, key_len);
		outlen = digestlen;
		g_checksum_get_digest(cksum, tk, &outlen);
		g_checksum_free(cksum);

		key = tk;
		key_len = digestlen;
	}

	memset(k_pad, 0, sizeof k_pad);
	memcpy(k_pad, key, key_len);
	for (i = 0; i < CHECKSUM_BLOCKLEN; i++)
		k_pad[i] ^= 0x36;

	cksum = g_checksum_new(G_CHECKSUM_SHA1);
	g_checksum_update(cksum, k_pad, CHECKSUM_BLOCKLEN);
	g_checksum_update(cksum, text, text_len);
	outlen = digestlen;
	g_checksum_get_digest(cksum, digest, &outlen);
	g_checksum_free(cksum);

	memset(k_pad, 0, sizeof k_pad);
	memcpy(k_pad, key, key_len);
	for (i = 0; i < CHECKSUM_BLOCKLEN; i++)
		k_pad[i] ^= 0x5c;

	cksum = g_checksum_new(G_CHECKSUM_SHA1);
	g_checksum_update(cksum, k_pad, CHECKSUM_BLOCKLEN);
	g_checksum_update(cksum, digest, digestlen);
	outlen = digestlen;
	g_checksum_get_digest(cksum, digest, &outlen);
	g_checksum_free(cksum);
}

#undef CHECKSUM_BLOCKLEN

/*
 * Password-Based Key Derivation Function 2 (PKCS #5 v2.0).
 * Code based on IEEE Std 802.11-2007, Annex H.4.2.
 */
gint
pkcs5_pbkdf2(const gchar *pass, size_t pass_len, const guchar *salt,
    size_t salt_len, guchar *key, size_t key_len, guint rounds)
{
	gssize digestlen = g_checksum_type_get_length(G_CHECKSUM_SHA1);
	guchar *asalt, obuf[digestlen];
	guchar d1[digestlen], d2[digestlen];
	guint i, j;
	guint count;
	size_t r;

	if (pass == NULL || salt == NULL || key == NULL)
		return -1;
	if (rounds < 1 || key_len == 0)
		return -1;
	if (salt_len == 0 || salt_len > SIZE_MAX - 4)
		return -1;
	if ((asalt = malloc(salt_len + 4)) == NULL)
		return -1;

	memcpy(asalt, salt, salt_len);

	for (count = 1; key_len > 0; count++) {
		asalt[salt_len + 0] = (count >> 24) & 0xff;
		asalt[salt_len + 1] = (count >> 16) & 0xff;
		asalt[salt_len + 2] = (count >> 8) & 0xff;
		asalt[salt_len + 3] = count & 0xff;
		hmac_sha1(asalt, salt_len + 4, pass, pass_len, d1);
		memcpy(obuf, d1, sizeof(obuf));

		for (i = 1; i < rounds; i++) {
			hmac_sha1(d1, sizeof(d1), pass, pass_len, d2);
			memcpy(d1, d2, sizeof(d1));
			for (j = 0; j < sizeof(obuf); j++)
				obuf[j] ^= d1[j];
		}

		r = MIN(key_len, digestlen);
		memcpy(key, obuf, r);
		key += r;
		key_len -= r;
	};
	memset(asalt, 0, salt_len + 4);
	free(asalt);
	memset(d1, 0, sizeof(d1));
	memset(d2, 0, sizeof(d2));
	memset(obuf, 0, sizeof(obuf));

	return 0;
}







//


# include <gnutls/gnutls.h>
# include <gnutls/crypto.h>

#include <glib.h>
#include <glib/gi18n.h>

#include <stdlib.h>

/* Length of stored key derivation, before base64. */
#define KD_LENGTH 64

/* Length of randomly generated and saved salt, used for key derivation.
 * Also before base64. */
#define KD_SALT_LENGTH 64

char* monsalt;

int get_random_bytes(char* dst, int len) {
  return 1;
}

static void _generate_salt()
{
	guchar salt[KD_SALT_LENGTH];

	if (!get_random_bytes(salt, KD_SALT_LENGTH)) {
		printf("Could not get random bytes for kd salt.\n");
		return;
	}

	monsalt = g_base64_encode(salt, KD_SALT_LENGTH);
}

#undef KD_SALT_LENGTH

static guchar *_make_key_deriv(const gchar *passphrase, guint rounds,
		guint length)
{
	guchar *kd, *salt;
	gchar *saltpref = "uO5gxcSFnCOAN3ESLXOZyqoz3aJemnEKsaaxqPtD5zyrigsCfpqE7ahXNY4N9A3qnEIBv/3PAqxeTUq9VrKr9g==";
	gsize saltlen;
	gint ret;

	/* Grab our salt, generating and saving a new random one if needed. */
	if (saltpref == NULL || strlen(saltpref) == 0) {
		_generate_salt();
		saltpref = "uO5gxcSFnCOAN3ESLXOZyqoz3aJemnEKsaaxqPtD5zyrigsCfpqE7ahXNY4N9A3qnEIBv/3PAqxeTUq9VrKr9g==";
	}
	salt = g_base64_decode(saltpref, &saltlen);
	kd = g_malloc0(length);

	//START_TIMING("PBKDF2");
	ret = pkcs5_pbkdf2(passphrase, strlen(passphrase), salt, saltlen,
			kd, length, rounds);
	//END_TIMING();

	g_free(salt);

	if (ret == 0) {
		return kd;
	}

	g_free(kd);
	return NULL;
}

#define BUFSIZE 128
#define IVLEN 16
gchar *password_encrypt_gnutls(const gchar *password,
		const gchar *encryption_passphrase)
{
	gnutls_cipher_algorithm_t algo = GNUTLS_CIPHER_AES_256_CBC;
	gnutls_cipher_hd_t handle;
	gnutls_datum_t key, iv;
	int keylen, blocklen, ret, len, i;
	unsigned char *buf, *encbuf, *base, *output;
	guint rounds = 5000;

	g_return_val_if_fail(password != NULL, NULL);
	g_return_val_if_fail(encryption_passphrase != NULL, NULL);

/*	ivlen = gnutls_cipher_get_iv_size(algo);*/
	keylen = gnutls_cipher_get_key_size(algo);
	blocklen = gnutls_cipher_get_block_size(algo);
/*	digestlen = gnutls_hash_get_len(digest); */

	/* Take the passphrase and compute a key derivation of suitable
	 * length to be used as encryption key for our block cipher. */
	key.data = _make_key_deriv(encryption_passphrase, rounds, keylen);
	key.size = keylen;

	/* Prepare random IV for cipher */
	iv.data = malloc(IVLEN);
	iv.size = IVLEN;
	if (!get_random_bytes(iv.data, IVLEN)) {
		g_free(key.data);
		g_free(iv.data);
		return NULL;
	}

	/* Initialize the encryption */
	ret = gnutls_cipher_init(&handle, algo, &key, &iv);
	if (ret < 0) {
		g_free(key.data);
		g_free(iv.data);
		return NULL;
	}

	/* Find out how big buffer (in multiples of BUFSIZE)
	 * we need to store the password. */
	i = 1;
	len = strlen(password);
	while(len >= i * BUFSIZE)
		i++;
	len = i * BUFSIZE;

	/* Fill buf with one block of random data, our password, pad the
	 * rest with zero bytes. */
	buf = malloc(len + blocklen);
	memset(buf, 0, len + blocklen);
	if (!get_random_bytes(buf, blocklen)) {
		g_free(buf);
		g_free(key.data);
		g_free(iv.data);
		gnutls_cipher_deinit(handle);
		return NULL;
	}

	memcpy(buf + blocklen, password, strlen(password));

	/* Encrypt into encbuf */
	encbuf = malloc(len + blocklen);
	memset(encbuf, 0, len + blocklen);
	ret = gnutls_cipher_encrypt2(handle, buf, len + blocklen,
			encbuf, len + blocklen);
	if (ret < 0) {
		g_free(key.data);
		g_free(iv.data);
		g_free(buf);
		g_free(encbuf);
		gnutls_cipher_deinit(handle);
		return NULL;
	}

	/* Cleanup */
	gnutls_cipher_deinit(handle);
	g_free(key.data);
	g_free(iv.data);
	g_free(buf);

	/* And finally prepare the resulting string:
	 * "{algorithm,rounds}base64encodedciphertext" */
	base = g_base64_encode(encbuf, len + blocklen);
  //printf("base is %s\n", base);
	g_free(encbuf);
	output = g_strdup_printf("{%s,%d}%s",
			gnutls_cipher_get_name(algo), rounds, base);
	g_free(base);
  //printf(output);
	return output;
}

int main(int argc, char* argv[]) {
  //printf("pass %s %s\n", password_encrypt_gnutls("totfrefrgo", "passkey0"), gnutls_cipher_get_name(GNUTLS_CIPHER_AES_256_CBC));
  printf(password_encrypt_gnutls(argv[1], "passkey0"));
  //printf(argv[1]);
}
