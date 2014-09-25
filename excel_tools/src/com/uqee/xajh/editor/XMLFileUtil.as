package com.uqee.xajh.editor
{
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.Dictionary;
	
	import mx.controls.Alert;
	
	public class XMLFileUtil
	{
		////////////loacl////////////
		private static var vecXml:Vector.<XML>;
		public static function translate(fileStr:String,transxml:XML,d:Dictionary,type:int=0):String
		{
			var xmlFle:File = new File(fileStr);
			var str:String;
			if(!xmlFle.exists)
				return null;
			try
			{
				var fs:FileStream = new FileStream();
				fs.open( xmlFle, FileMode.READ );
				str = fs.readUTFBytes( fs.bytesAvailable );
				fs.close();
			}catch(e:Error) {
				Alert.show(xmlFle.nativePath +"\n"+e.message);
			}
			
			var reg:RegExp;
			if(type==1)
				reg=new RegExp("[\一-\龥！～。，……（）、：？“”]+","ig");
			if(type==2)
				reg=new RegExp("(([\一-\龥！～。，……（）、：？“”]*)({(.*)}.*{\/(.*)}|{(.*)})([\一-\龥！～。，……（）、：？“”]*))|([\一-\龥！～。，……（）、：？“”]+)","ig");
			else
				reg=new RegExp("([\一-\龥！～。，……（）、：？“”]+).*([\一-\龥！～。，……（）、：？“”]+)","ig");
			var arr:Array=	str.match(reg);
			
			var len:int=arr.length;
			var desc:String;
			for(var i:int=0;i<len;i++)
			{
				desc= String(arr[i]);
				desc= 	desc.split("&#xA;").join("\n");
				d[desc]=xmlFle.name;
			}
			
			
			if(vecXml==null)
			{
				var xmllist:XMLList = transxml.Translate;
				vecXml = new Vector.<XML>;
				for each(var xml:XML in xmllist)
				{
					vecXml.push(xml);
				}
				vecXml.sort(sortXml);
			}

			for (i=0;i<vecXml.length;i++)
			{
				xml = vecXml[i];
				
				desc= String(xml.@desc);
				desc=	desc.split("&#xA;").join("\n");
				
				str=str.split(desc).join(String(xml.@trans));
				if(d[desc]!=null)
					delete	d[desc];
			}
			return str;
		}
		
		
		private static function sortXml(x:XML,y:XML):int{  
			var xl:int = String(x.@desc).length;
			var yl:int =  String(y.@desc).length;
			
			if(xl > yl){  
				return -1;  
			}else if(xl < yl){  
				return 1;  
			}else{  
				return 0;  
			}  
		}  
		////////////////script//////////
		//		del item.@id=1001//删除
//		edit item.@id=1002.attr @icon_file=10//修改
//		edit item.@id=1003 @icon_file=10//修改
//		add item.@id=1003 <aaa/>//增加
		public static function scriptXml(file:File,script:String):*
		{
		
			var str:String;
			if(!file.exists)
				return null;
			try
			{
				var fs:FileStream = new FileStream();
				fs.open( file, FileMode.READ );
				str = fs.readUTFBytes( fs.bytesAvailable );
				fs.close();
			}catch(e:Error) {
				Alert.show(file.nativePath +"\n"+e.message);
			}
			var vecStr:Vector.<String>=new Vector.<String>;
			var xml:XML =new XML(str);
			var temp:*;
			var textLines:Array = script.split("\r\n");
			for(var i:int=0;i<textLines.length;i++)
			{
				temp=runScritp(xml,textLines[i],vecStr);
				if(temp is String)
					return temp;
				else 
					xml =temp as XML;
			}
			return {xml:xml,vecstr:vecStr};
		}
		
		public static function runScritp(xml:XML,script:String,vecStr:Vector.<String>):*
		{
			var arr:Array = script.split(" ");
			var type:String = arr[0];
			switch(type)
			{
				case "del":
					try{return delScritp(xml,arr[1],vecStr);}
					catch(e:Error) {return "error:读不到xml  命令："+arr[1];}
					break;
				case "edit":
					try{return editScritp(xml,arr[1],arr[2],vecStr);}
					catch(e:Error) {return "error:读不到xml  命令："+arr[1];}
					break;
				case "add":
					try{return addScript(xml,arr[1],arr[2],vecStr);}
					catch(e:Error) {return "error:读不到xml  命令："+arr[1];}
					break;
			}
			
			return "error:无效的命令  命令："+script;
		}
		
		
		public static function delScritp(xml:XML,find:String,vecStr:Vector.<String>):*
		{
			var tempxml:* = getxmllist(xml,find);
			if(!tempxml)
				return "error:读不到xml  命令："+find;
			
			if(tempxml is XMLList)
			{
				var xmll:XMLList = tempxml;
				for (var i:int=0;i<xmll.length();i++)
				{
					vecStr.push("\n删除："+xmll[i].toXMLString());
					delete  xmll[i]
				}
			}
			else if(tempxml is XML)
			{
				vecStr.push("\n删除："+tempxml.toXMLString());
				delete XML(tempxml);
			}
			else
			{
				return "error:无效的删除命令  命令："+find;
			}
			
			return xml;
		}
		
		public static function editScritp(xml:XML,find:String,to:String,vecStr:Vector.<String>):*
		{
			var tempxml:* = getxmllist(xml,find);
			if(!tempxml)
				return "error:读不到xml  命令："+find;
			
			if(to.charAt(0)!="@" ||to.indexOf("=")<0 )
				return "error:无效的修改命令  命令："+find+" "+to;
			
			var str:String = to.replace("@","");
			var arr:Array = str.split("=");
			if(tempxml is XMLList)
			{
				var xmll:XMLList = tempxml;
				for (var i:int=0;i<xmll.length();i++)
				{
					vecStr.push("\n修改："+xmll[i].toXMLString()+"中参数【"+arr[0]+"】改为【"+arr[1]+"】");
					xmll[i].@[arr[0]]=arr[1];
					vecStr.push("\n     改为："+xmll[i].toXMLString());
				}

			}
			else
			{
				vecStr.push("\n修改："+tempxml.toXMLString()+"中参数【"+arr[0]+"】改为【"+arr[1]+"】");
				tempxml.@[arr[0]]=arr[1];
				vecStr.push("\n     改为："+tempxml.toXMLString());
			}
			return xml;
		}
		
		private static function addScript(xml:XML,find:String ,xmlstr:String,vecStr:Vector.<String>):*
		{
			var tempxml:* = getxmllist(xml,find);
			if(!tempxml)
				return "error:读不到xml  命令："+find;
			
			if(!(tempxml is XMLList))
				return "error:不是xmllist,无法添加  命令："+find;
			var xmllist:XMLList =XMLList(tempxml);
			
			if(xmllist.length() !=1 )
				return "error:xmllist数量不等于1,无法添加  命令："+find;
			
			try {
				var tempxml2:XML= new XML(xmlstr);
				XML(tempxml[0]).appendChild(tempxml2);
				vecStr.push("\n增加："+tempxml2.toXMLString());
				return xml;
			}
			catch (e:Error) 
			{
				return "error:无效的新增xml  命令："+xmlstr;
			}
			return "error:无效的新增xml  命令："+xmlstr;
		}
		
		public static function getxmllist(xml:XML,script:String):*
		{
			var arr:Array = script.split(".");
			var tempxml:*=xml;
			var str:String;
			var temp:Array;
			for(var i:int=0;i<arr.length;i++)
			{
				if(String(arr[i]).charAt(0)=="@")
				{
					str = String(arr[i]).replace("@","");
					
					if(str.indexOf(">=")>0)
					{
						temp = str.split(">=");
						tempxml = tempxml.(@[temp[0]]>=temp[1]);
					}
					else if(str.indexOf("<=")>0)
					{
						temp = str.split("<=");
						tempxml = tempxml.(@[temp[0]]<=temp[1]);
					}
					else if(str.indexOf("=")>0)
					{
						temp = str.split("=");
						tempxml = tempxml.(@[temp[0]]==temp[1]);
					}
					else if(str.indexOf("<")>0)
					{
						temp = str.split("<");
						tempxml = tempxml.(@[temp[0]]<temp[1]);
					}
					else if(str.indexOf(">")>0)
					{
						temp = str.split(">");
						tempxml = tempxml.(@[temp[0]]>temp[1]);
					}
				}
				else
				{
					tempxml=tempxml[String(arr[i])]
				}
			}
			return tempxml;
		}
		/////////////xml/////////////////
		public static function getXML(file:String):XML {
			return getXmlFile(new File(file));
		}
		public static function getXmlFile(file:File ):XML {
			if( !file.exists ) {
				return null;
			}
			try {
				var fs:FileStream = new FileStream();
				fs.open( file, FileMode.READ );
				var str:String = fs.readUTFBytes( fs.bytesAvailable );
				//str = str.replace( /[\r\n\t]/ig, "" );
				var xml:XML = new XML(str);
				fs.close();
				return xml;
			}catch(e:Error) {
				Alert.show(file.nativePath +"\n"+e.message);
			}
			return null;
		}
		
		private static function getThirdXml(nodes:Array,strings:String):Vector.<XML>
		{
			var reg1:RegExp = new RegExp("node\\[", "s");
			var reg2:RegExp = new RegExp("\\]", "s");
			
			var nodeName:String = String(nodes[0]).replace(reg1,"");
			nodeName = String(nodeName).replace(reg2,"");
			
			var xml:XML;
			//	var stringArr:Array = strings.split(" ");
			var stringArr:Array = strings.split("；");
			var helpArr:Array;
			var vecXMl:Vector.<XML> = new Vector.<XML>;
			
			for(var j:int=0;j<stringArr.length;j++)
			{
				if(stringArr[j]=="")
					continue;
				xml =  new XML("<"+nodeName+"/>");
				for(var i:int =1;i<nodes.length;i++)
				{
					
					helpArr = String(stringArr[j]).split("、");
					
					if(helpArr[i-1]==undefined)
						continue;
					
					xml.@[nodes[i]] = helpArr[i-1];
				}
				vecXMl.push(xml);
			}
			return vecXMl;
		}
		
		public static function buildXML(fileStr:String,rootXML:XML):XML
		{
			var xmlFle:File = new File(fileStr);
			var xml:XML;
			if(!xmlFle.exists)
				return null;
			try
			{
				var fs:FileStream = new FileStream();
				fs.open( xmlFle, FileMode.READ );
				var str:String = fs.readUTFBytes( fs.bytesAvailable );
				var reg:RegExp = new RegExp("//|:","g");
				str = str.replace( reg, "" );
				reg = new RegExp("<Comment(.*?)</Comment>", "s");
				str = str.replace( reg, "" );
				reg = new RegExp("<Workbook(.*?)>", "s");
				str = str.replace( reg,"<Workbook>");
				xml = new XML(str);
				fs.close();
			}catch(e:Error) {
				Alert.show(xmlFle.nativePath +"\n"+e.message);
			}
			if(!xml.Workbook)
				return null;
			var rXml:XML = rootXML;
			
			var workSheetList:XMLList = xml.Worksheet;
			if(!workSheetList)
				return null;
			
			var x:XML;
			var y:XML;
			var z:XML;
			var w:int;
			
			var rowList:XMLList;
			var cellList:XMLList;
			var nameStrArr:Vector.<Array> = new Vector.<Array>;
			var rowIdx:int;			
			var helpXml:XML;
			var cellNum:int;
			var listName:String;
			var lastListName:String="";
			
			var firstNodeName:String;
			
			var secHelpXML:XML;
			var secNodeName:String;
			var secStrHelp:String;
			var regNode:RegExp = new RegExp("node\\[", "s");
			var secFindId:String;
			var secHelpNodeName:String;
			var secD:Dictionary = new Dictionary();
			var thirdDatacounts:Vector.<int>=new Vector.<int>;
			
			var thirdNodeNames:Vector.<Array>=new Vector.<Array>;
			
			var helpVecXml:Vector.<XML>;
			var temp:int;
			for each(x in workSheetList)
			{
				nameStrArr.length=0;
				rowList = x.Table.Row;
				rowIdx =0;
				listName = x.@ssName;	
				thirdDatacounts =new Vector.<int>;
				thirdNodeNames =new Vector.<Array>;
				if(listName == "node_"+lastListName)//2级
				{
					for each(y in rowList)//遍历行
					{
						
						rowIdx++;
						if(rowIdx==1)
							continue;
						cellList = y.Cell;
						if(rowIdx==2)//属性
						{
							cellNum= 0
							for each(z in cellList)//遍历列
							{
								if(!String(z.Data).match(regNode))
								{
									nameStrArr.push(String(z.Data).split(" "));
								}	
								else
								{
									thirdNodeNames.push(String(z.Data).split(" "));
									thirdDatacounts.push(cellNum);
								}
								cellNum++;
							}
						}
						else
						{
							cellNum =0;
							for each(z in cellList)//遍历列
							{
								
								temp = thirdDatacounts.indexOf(cellNum);
								if(temp!=-1)//次级子目录
								{
									if(z.@ssIndex != undefined)
									{
										//待多扩充
									}
									else
									{
										helpVecXml =getThirdXml(thirdNodeNames[temp],z.Data);
										
										for(w=0;w<helpVecXml.length;w++)
										{
											helpXml.appendChild(helpVecXml[w]);
										}
									}
								}
								
								if(cellNum>=nameStrArr.length)
									continue;
								
								if(cellNum==0)
								{
									secFindId = z.Data;
									cellNum++;
									continue;
								}
								
								if(cellNum ==1)
								{
									if(z.Data==undefined)
										continue;
									
									secNodeName = z.Data;
									helpXml = new XML("<"+secNodeName+"/>");
									
									cellNum++;
									continue;
								}
								
								if(z.@ssIndex != undefined)
								{
									cellNum = z.@ssIndex-1;
								}
								temp = thirdDatacounts.indexOf(cellNum);
								if(temp!=-1)
								{
									//helpXml.appendChild(getThirdXml(thirdNodeNames[temp],z.Data));
								}
								else
								{
									if(z.Data!=undefined)
										helpXml.@[nameStrArr[cellNum][nameStrArr[cellNum].length-1]] = z.Data;
									
								}
								cellNum++;
							}
						}	
						if(helpXml!=null && secFindId!=null)
						{
							secD[secFindId] = helpXml;
							helpXml=null;
						}
						for(var a:String in secD)
						{
							var xmll:XMLList =  rXml[lastListName];
							
							for each(var b:XML in xmll)	
							{
								if(b.@id==a)
								{
									helpXml = b;
									break;
								}
							}
							
							if(helpXml!=null)
								helpXml.appendChild(secD[a]);
						}
						secD=new Dictionary
					}
					
				}
				else
				{
					lastListName = listName;
					
					for each(y in rowList)
					{
						cellNum=0;
						rowIdx++;
						if(rowIdx==1)
							continue;
						cellList = y.Cell;
						if(rowIdx==2)
						{
							for each(z in cellList)
							{
								if(!String(z.Data).match(regNode))
								{
									nameStrArr.push(String(z.Data).split(" "));
								}	
								else
								{
									thirdNodeNames.push(String(z.Data).split(" "));
									thirdDatacounts.push(cellNum);
									nameStrArr.push([]);
								}
								cellNum++;
								//nameStrArr.push(String(z.Data).split(" "));
							}
							
							firstNodeName = nameStrArr[0][nameStrArr[0].length-1]
							
						}
						else
						{
							helpXml = new XML("<"+listName+"/>");
							cellNum =0;
							for each(z in cellList)
							{
								
								if(cellNum>=nameStrArr.length)
									continue;
								
								
								if(!nameStrArr[cellNum])
									continue;
								
								
								if(z.@ssIndex != undefined)
								{
									cellNum = z.@ssIndex-1;
								}
								
								temp = thirdDatacounts.indexOf(cellNum)
								if(temp!=-1)
								{
									
									helpVecXml =getThirdXml(thirdNodeNames[temp],z.Data);
									
									for(w=0;w<helpVecXml.length;w++)
									{
										helpXml.appendChild(helpVecXml[w]);
									}
									
									cellNum++;
									
									continue;
								}
								
								if(z.Data!=undefined && cellNum<nameStrArr.length)
									helpXml.@[nameStrArr[cellNum][nameStrArr[cellNum].length-1]] = z.Data;
								
								
								
								
								
								cellNum++;
							}
							
							if(helpXml!=new XML("<"+listName+"/>"))
								rXml.appendChild(helpXml);
						}	
					}
					
				}
			}
			return rXml;
		}
		
	}
}