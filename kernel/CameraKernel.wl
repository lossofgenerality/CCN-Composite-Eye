(* ::Package:: *)
(* CameraKernel — CCN Cloud backend for CCN Camera (Snap to Text).
   Same design as LaplacianLabKernel: "wolfram" mode evaluates code, "chat" mode
   forwards a Claude Messages request using a key kept in a private Cloud object.
   Run from a signed-in Mathematica or Wolfram Cloud notebook.
   (c) Computational Classnotes · CC BY-NC-SA 4.0 *)

(* Step 1, once: store the Claude API key privately *)
CloudPut["PASTE-THE-CLAUDE-API-KEY-HERE", "CameraKernel/apikey", Permissions -> "Private"]

(* Step 2: deploy. The secret is the WOLFRAM_KEY typed into the page. Same name keeps the URL:
   https://www.wolframcloud.com/obj/<account>/CameraKernel *)
With[{keyObj = CloudObject["CameraKernel/apikey"], secret = "CHOOSE-A-LONG-SECRET"},
 CloudDeploy[
  APIFunction[
   {"code" -> "String" -> "", "code_b64" -> "String" -> "", "key" -> "String",
    "mode" -> "String" -> "wolfram", "payload_b64" -> "String" -> ""},
   Module[{b64s, fromB64, chatCall, chat, code},
    b64s[s_String] := BaseEncode[StringToByteArray[s]];
    fromB64[b_String] := Quiet@Check[ByteArrayToString[BaseDecode[b]], ""];
    chatCall[payload_String, apiKey_String] := Module[{p, model, resp, body, status},
      p = Quiet@Check[ImportByteArray[StringToByteArray[payload], "RawJSON"], $Failed];
      If[! AssociationQ[p] || ! ListQ[p["messages"]], Return[<|"error" -> "bad payload", "status" -> 400|>]];
      model = Replace[p["model"], Except[_String?(StringStartsQ["claude-"])] -> "claude-sonnet-5-5"];
      resp = URLRead[HTTPRequest["https://api.anthropic.com/v1/messages", <|"Method" -> "POST",
          "Headers" -> {"x-api-key" -> apiKey, "anthropic-version" -> "2023-06-01", "content-type" -> "application/json"},
          "Body" -> ExportByteArray[DeleteMissing@<|"model" -> model,
              "max_tokens" -> Clip[Replace[p["max_tokens"], Except[_Integer] -> 1500], {1, 4096}],
              "system" -> p["system"], "messages" -> p["messages"]|>, "RawJSON", "Compact" -> True]|>],
        TimeConstraint -> 110];
      If[FailureQ[resp], Return[<|"error" -> "chat service unreachable", "status" -> 502|>]];
      status = resp["StatusCode"];
      body = Quiet@Check[ImportByteArray[resp["BodyByteArray"], "RawJSON"], <||>];
      If[status === 200 && AssociationQ[body],
       <|"text_b64" -> b64s@StringJoin[Cases[Lookup[body, "content", {}],
            KeyValuePattern[{"type" -> "text", "text" -> t_String}] :> t]],
         "stop_reason" -> Lookup[body, "stop_reason", ""]|>,
       <|"error" -> If[AssociationQ[body], Lookup[Lookup[body, "error", <||>], "message", "chat request failed"], "chat request failed"],
         "status" -> status|>]];
    chat = Quiet@Check[CloudGet[keyObj], ""];
    chat = If[StringQ[chat], StringTrim[chat], ""];
    Which[
     #key =!= secret,
      Failure["Forbidden", <|"Message" -> "bad key"|>],
     #mode === "chat",
      If[chat === "", <|"error" -> "no chat key stored", "status" -> 503|>,
       chatCall[fromB64[#["payload_b64"]], chat]],
     True,
      code = If[#["code_b64"] =!= "", fromB64[#["code_b64"]], #code];
      Module[{r = TimeConstrained[ToExpression[code], 60, $Aborted], img, txt},
       img = If[FreeQ[r, _Graphics | _Graphics3D | _Image | _Legended], "",
         BaseEncode[ExportByteArray[Rasterize[r, ImageResolution -> 110], "PNG"]]];
       txt = ToString[r /. g : (_Graphics | _Graphics3D | _Image | _Legended) :> "-Graphics-", InputForm];
       <|"text" -> txt, "text_b64" -> b64s[txt], "image" -> img, "chat_ready" -> chat =!= ""|>]
     ]] &,
   "JSON"],
  "CameraKernel", Permissions -> "Public"]]

(* Connection check the page runs (expects {version, 2, 6}):
   {$VersionNumber, 1 + 1, \[CapitalDelta][1][x^2 + y^2 + z^2]}  -- sent after the Δ prelude *)
