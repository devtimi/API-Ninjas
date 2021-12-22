#tag Class
Protected Class APINinjas
	#tag Method, Flags = &h0
		Sub ImageToText(fImage as FolderItem)
		  var oSock as new URLConnection
		  oSock.RequestHeader("X-Api-Key") = kAPIKey
		  
		  var dictData as new Dictionary
		  dictData.Value("image") = fImage
		  
		  SetFormData(oSock, dictData)
		  
		  AddHandler oSock.ContentReceived, WeakAddressOf SocketContentReceived
		  AddHandler oSock.Error, WeakAddressOf SocketError
		  
		  maroSockets.Add(oSock)
		  
		  // Send the request
		  oSock.Send("POST", "https://api.api-ninjas.com/v1/imagetotext")
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function MIMEType(fTarget as FolderItem) As String
		  var arsParts() as String = fTarget.Name.Split("")
		  var sExtension as String = arsParts(arsParts.LastIndex)
		  
		  select case sExtension
		    
		  case "jpg"
		    return "image/jpeg"
		    
		  case "jpeg"
		    return "image/jpeg"
		    
		  case "png"
		    return "image/png"
		    
		  end select
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ParseResponseItem(jsItem as JSONItem)
		  // This is where we look for responses we can handle
		  if jsItem.HasKey("text") then
		    RaiseEvent ImageTextReceived(jsItem.Value("text").StringValue.DefineEncoding(Encodings.UTF8))
		    
		  elseif jsItem.HasKey("language") then
		    var lang, iso as String
		    
		    lang = jsItem.Value("language").StringValue.DefineEncoding(Encodings.UTF8)
		    iso = jsItem.Value("iso").StringValue.DefineEncoding(Encodings.UTF8)
		    
		    RaiseEvent DocumentLanguageReceived(lang, iso)
		    
		  end
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub RemoveHandlers(oSock as URLConnection)
		  // Remove the handlers when destroying the object
		  RemoveHandler oSock.ContentReceived, WeakAddressOf SocketContentReceived
		  RemoveHandler oSock.Error, WeakAddressOf SocketError
		  
		  // Remove the reference to the object
		  for i as Integer = maroSockets.LastIndex downto 0
		    var oThis as URLConnection = maroSockets(i)
		    
		    if oThis = oSock then
		      maroSockets(i) = nil
		      maroSockets.RemoveAt(i)
		      exit for i
		      
		    end
		    
		  next i
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub SetFormData(sock as URLConnection, FormData as Dictionary)
		  // Adapted and updated from
		  // https://www.boredomsoft.org/file-uploads-form-encodings-and-xojo.bs
		  
		  // Generate a boundary
		  var sBoundary as String = "--" + EncodeHex(MD5(System.Microseconds.ToString)).Right(24) + "-bOuNdArY"
		  
		  static CRLF as String = EndOfLine.Windows
		  
		  var data as new MemoryBlock(0)
		  var out as new BinaryStream(data)
		  
		  for each key as String in FormData.Keys
		    out.Write("--" + sBoundary + CRLF)
		    
		    if VarType(FormData.Value(Key)) = Variant.TypeString then
		      out.Write("Content-Disposition: form-data; name=""" + key + """" + CRLF + CRLF)
		      out.Write(FormData.Value(key) + CRLF)
		      
		    elseif FormData.Value(Key) isa FolderItem then
		      var file as FolderItem = FormData.Value(key)
		      out.Write("Content-Disposition: form-data; name=""" + key + """; filename=""" + File.Name + """" + CRLF)
		      out.Write("Content-Type: " + MIMEType(file) + CRLF + CRLF)
		      
		      var bs as BinaryStream = BinaryStream.Open(File)
		      out.Write(bs.Read(bs.Length) + CRLF)
		      bs.Close
		      
		    end
		    
		  next
		  
		  out.Write("--" + sBoundary + "--" + CRLF)
		  out.Close
		  
		  sock.SetRequestContent(data, "multipart/form-data; boundary=" + sBoundary)
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub SocketContentReceived(oSender as URLConnection, sURL as String, iCode as Integer, sContent as String)
		  #pragma unused sURL
		  
		  sContent = sContent.DefineEncoding(Encodings.UTF8)
		  
		  try
		    var jsResponse as new JSONItem(sContent.Trim)
		    
		    if iCode = 200 then
		      if sURL.IndexOf("/v1/textlanguage") > -1 then // TextLanguage response
		        ParseResponseItem(jsResponse)
		        
		      elseif sURL.IndexOf("/v1/imagetotext") > -1 then // ImageToText response
		        // Iterate the response array
		        var iMax as Integer = jsResponse.Count - 1
		        for i as Integer = 0 to iMax
		          var jsThis as JSONItem = jsResponse.ChildAt(i)
		          ParseResponseItem(jsThis)
		          
		        next i
		        
		      end if
		      
		    else
		      // Error occured
		      var sMessage as String = jsResponse.Lookup("error", "")
		      RaiseEvent RequestError(iCode, sMessage)
		      
		    end
		    
		  catch ex as JSONException
		    // Bad response content
		    RaiseEvent RequestError(ex.ErrorNumber, ex.Message)
		    
		  end try
		  
		  RemoveHandlers(oSender)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub SocketError(oSender as URLConnection, ex as RuntimeException)
		  RequestError(ex.ErrorNumber, ex.Message)
		  
		  RemoveHandlers(oSender)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		  var oSock as new URLConnection
		  oSock.RequestHeader("X-Api-Key") = kAPIKey
		Sub TextLanguage(sText As String)
		  // The API limits the document to 1000 characters
		  if sText.Length > 1000 then sText = sText.Right(1000)
		  sText = sText.ReplaceLineEndings(EndOfLine.UNIX)
		  
		  AddHandler oSock.ContentReceived, WeakAddressOf SocketContentReceived
		  AddHandler oSock.Error, WeakAddressOf SocketError
		  
		  maroSockets.Add(oSock)
		  
		  // Send the request
		  oSock.Send("GET", "https://api.api-ninjas.com/v1/textlanguage?text=" + EncodeURLComponent(sText))
		End Sub
	#tag EndMethod


	#tag Hook, Flags = &h0
		Event DocumentLanguageReceived(Language As String, ISOCode As String)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event ImageTextReceived(sText as String)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event RequestError(iCode as Integer, sMessage as String)
	#tag EndHook


	#tag Property, Flags = &h21
		Private maroSockets() As URLConnection
	#tag EndProperty


	#tag Constant, Name = kAPIKey, Type = String, Dynamic = False, Default = \"", Scope = Private
	#tag EndConstant


	#tag ViewBehavior
		#tag ViewProperty
			Name="Name"
			Visible=true
			Group="ID"
			InitialValue=""
			Type="String"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Index"
			Visible=true
			Group="ID"
			InitialValue="-2147483648"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Super"
			Visible=true
			Group="ID"
			InitialValue=""
			Type="String"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Left"
			Visible=true
			Group="Position"
			InitialValue="0"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Top"
			Visible=true
			Group="Position"
			InitialValue="0"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
