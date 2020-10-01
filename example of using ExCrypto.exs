arbitrary_data = %{id: 6, name: "test"}

clear_text = :erlang.term_to_binary(arbitrary_data)
{:ok, aes_256_key} = ExCrypto.generate_aes_key(:aes_256, :bytes)
{:ok, {init_vec, cipher_text}} = ExCrypto.encrypt(aes_256_key, clear_text)
16 = String.length(init_vec)
{:ok, val} = ExCrypto.decrypt(aes_256_key, init_vec, cipher_text)
val = clear_text
:erlang.binary_to_term(val)
