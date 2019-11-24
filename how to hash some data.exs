:crypto.hash(:sha256, "string data")|> Base.encode32(padding: false) |> String.downcase
