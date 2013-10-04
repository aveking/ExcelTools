package com
{
	import flash.events.FileListEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import mx.controls.Alert;
	
	public class FileUtil
	{
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
		
		public static function LoadExcelXmlFile(file:String):XMLList{
			var xmlFle:File = new File(file);
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
						
			var workSheetList:XMLList = xml.Worksheet;
			if(!workSheetList)
				return null;

			return workSheetList;
		}

		public static function buildXML(fileStr:String, rootXML:XML):XML
		{
			var rXml:XML = rootXML;
			var workSheetList:XMLList = LoadExcelXmlFile(fileStr);
			
			var xqqqqq:XML;
			var ywwwww:XML;
			var zeeeeee:XML;
			var wrrrrrr:int;
			
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
			var regSec1:RegExp = new RegExp("node\\[", "s");
			var secFindId:String;
			var secHelpNodeName:String;
			var secD:Dictionary = new Dictionary();
			var thirdDatacounts:Vector.<int>=new Vector.<int>;
			
			var thirdNodeNames:Vector.<Array>=new Vector.<Array>;
			
			var helpVecXml:Vector.<XML>;
			var temp:int;
			for each(xqqqqq in workSheetList)
			{
				nameStrArr.length=0;
				rowList = xqqqqq.Table.Row;
				rowIdx =0;
				listName = xqqqqq.@ssName;	
				thirdDatacounts =new Vector.<int>;
				thirdNodeNames =new Vector.<Array>;
				if(listName == "node_"+lastListName)
				{
					for each(ywwwww in rowList)
					{
						
						rowIdx++;
						if(rowIdx==1)
							continue;
						cellList = ywwwww.Cell;
						if(rowIdx==2)
						{
							cellNum= 0
							for each(zeeeeee in cellList)
							{
								if(!String(zeeeeee.Data).match(regSec1))
								{
									nameStrArr.push(String(zeeeeee.Data).split(" "));
								}	
								else
								{
									thirdNodeNames.push(String(zeeeeee.Data).split(" "));
									thirdDatacounts.push(cellNum);
								}
								cellNum++;
							}
						}
						else
						{
							cellNum =0;
							for each(zeeeeee in cellList)
							{
								
								temp = thirdDatacounts.indexOf(cellNum);
								if(temp!=-1)
								{
									if(zeeeeee.@ssIndex != undefined)
									{
										//待多扩充
									}
									else
									{
										helpVecXml =getThirdXml(thirdNodeNames[temp],zeeeeee.Data);
										
										for(wrrrrrr=0;wrrrrrr<helpVecXml.length;wrrrrrr++)
										{
											helpXml.appendChild(helpVecXml[wrrrrrr]);
										}
									}
								}
								
								if(cellNum>=nameStrArr.length)
									continue;
								
								if(cellNum==0)
								{
									secFindId = zeeeeee.Data;
									cellNum++;
									continue;
								}
								
								if(cellNum ==1)
								{
									if(zeeeeee.Data==undefined)
										continue;
									
									secNodeName = zeeeeee.Data;
									helpXml = new XML("<"+secNodeName+"/>");
									
									cellNum++;
									continue;
								}
								
								if(zeeeeee.@ssIndex != undefined)
								{
									cellNum = zeeeeee.@ssIndex-1;
								}
								temp = thirdDatacounts.indexOf(cellNum);
								if(temp!=-1)
								{
									helpXml.appendChild(getThirdXml(thirdNodeNames[temp],zeeeeee.Data));
								}
								else
								{
									if(zeeeeee.Data!=undefined)
										helpXml.@[nameStrArr[cellNum][nameStrArr[cellNum].length-1]] = zeeeeee.Data;
									
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
					
					for each(ywwwww in rowList)
					{
						cellNum=0;
						rowIdx++;
						if(rowIdx==1)
							continue;
						cellList = ywwwww.Cell;
						if(rowIdx==2)
						{
							for each(zeeeeee in cellList)
							{
								if(!String(zeeeeee.Data).match(regSec1))
								{
									nameStrArr.push(String(zeeeeee.Data).split(" "));
								}	
								else
								{
									thirdNodeNames.push(String(zeeeeee.Data).split(" "));
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
							for each(zeeeeee in cellList)
							{
								
								if(cellNum>=nameStrArr.length)
									continue;
								
								
								if(!nameStrArr[cellNum])
									continue;
								
								
								if(zeeeeee.@ssIndex != undefined)
								{
									cellNum = zeeeeee.@ssIndex-1;
								}
								
								temp = thirdDatacounts.indexOf(cellNum)
								if(temp!=-1)
								{
									
									helpVecXml =getThirdXml(thirdNodeNames[temp],zeeeeee.Data);
									
									for(wrrrrrr=0;wrrrrrr<helpVecXml.length;wrrrrrr++)
									{
										helpXml.appendChild(helpVecXml[wrrrrrr]);
									}
									
									cellNum++;
									
									continue;
								}
								
								if(zeeeeee.Data!=undefined && cellNum<nameStrArr.length)
									helpXml.@[nameStrArr[cellNum][nameStrArr[cellNum].length-1]] = zeeeeee.Data;
								
								
								
								
								
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