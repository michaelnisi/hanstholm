//
//  ParserTests.swift
//
//
//  Created by Michael Nisi on 07.04.24.
//

import XCTest
@testable import Hyde

final class ParserTests: XCTestCase {
    private var parts: [String.SubSequence]!
    
    override func setUp() async throws {
        try await super.setUp()
        
        self.parts = try html.stripOutHtml().splitLines()
    }
    
    func testWave() async throws {
        XCTAssertEqual(String(parts.middleWaveHeight()!), "1,05")
        XCTAssertEqual(String(parts.maxWaveHeight()!), "2,03")
        XCTAssertEqual(String(parts.wavePeriod()!), "5,7")
        XCTAssertEqual(String(parts.currentDirection()!), "ØNØ")
    }
    
    func testWind() async throws {
        XCTAssertEqual(String(parts.windGust()!), "17,4")
        XCTAssertEqual(String(parts.windMiddle()!), "12,9")
        XCTAssertEqual(String(parts.windCurrent()!), "10,9")
        XCTAssertEqual(String(parts.windDirection()!), "SV")
    }
}

let html = """
<html>

<head>
<script Language="JavaScript">

 
function tooltip(billede,navn)
  {
  var tooltipPot = open('stat.asp', 'Kurver', 'toolbar=no,location=no,status=no,menubar=no,scrollbars=yes,resizable=no,directories=no,top=0,left=20,width=700, height=800 ');
      
  }

</script>
<meta http-equiv="Content-Language" content="da">
<meta http-equiv="REFRESH" content="60">

<title>Hanstholm Havn</title>

<meta NAME="robots" CONTENT="index,follow">
<meta NAME="revisit-after" CONTENT="21 days"><link rel="stylesheet" href="style.css" type="text/css">
<script language="JavaScript" SRC="../_struktur/css/1script.js"></script>
</head>

<body topmargin="10" leftmargin="0">
<div align="center">
  <center>
  <table border="1" cellpadding="0" cellspacing="0" style="border-collapse: collapse" bordercolor="#111111" width="100%" class="vstable">
    <tr>
      <td width="100%"><p align="center"><font size="5" color="#005599">Vejret Hanstholm Havn</font></p></td>
    </tr>
    <tr>
      <td width="100%">
    <!--1***********************************************************-->
    <table border="0" cellpadding="4" style="border-collapse: collapse" bordercolor="#111111" width="100%">
        <tr>
          <td width="25%" align="center">
   <table border="0" cellpadding="0" cellspacing="0" style="border-collapse: collapse" bordercolor="#111111" width="100%" class="vsdatatable">
      <tr>
        <td nowrap colspan="2" class="vsdataoverskrift">Strømretning</td>
      </tr>
      <tr>
        <td nowrap class="vsdatavalue" valign="bottom">ØNØ</td>
        <td nowrap valign="bottom" class="vsdatavaluev">65°</td>
      </tr>
      
    </table>
          </td>
          <td width="25%" align="center">
    <table border="0" cellpadding="0" cellspacing="0" style="border-collapse: collapse" bordercolor="#111111" width="100%" class="vsdatatable">
   <tr>
        <td nowrap colspan="2" class="vsdataoverskrift">Aktuel vindhastighed</td>
      </tr>
      <tr>
        <td nowrap class="vsdatavalue" valign="bottom">10,9</td>
        <td nowrap valign="bottom" class="vsdatavaluev">m/s</td>
      </tr>
    
    </table>
          </td>
          <td width="25%" align="center">
    <table border="0" cellpadding="0" cellspacing="0" style="border-collapse: collapse" bordercolor="#111111" width="100%" class="vsdatatable">
       <tr>
        <td nowrap colspan="3" class="vsdataoverskrift">Aktuel vindretning</td>
      </tr>
      <tr>
        <td nowrap align="center"></td>
        <td nowrap class="vsdatavalue" valign="bottom">SV</td>
        <td nowrap valign="bottom" class="vsdatavaluev">218°</td>
      </tr>
            
    </table>
      </td>
        <td width="25%" align="center">
    <table border="0" cellpadding="0" cellspacing="0" style="border-collapse: collapse" bordercolor="#111111" width="100%" class="vsdatatable">
     <tr>
        <td nowrap colspan="2" class="vsdataoverskrift">Max Bølgehøjde  </td>
      </tr>
      <tr>
        <td nowrap class="vsdatavalue" valign="bottom">2,03</td>
        <td nowrap valign="bottom" class="vsdatavaluev">m</td>
      </tr>
    </table>
          </td>
        </tr>
   <!--2***********************************************************-->
        <tr>
          <td width="25%" align="center">
   
    <table border="0" cellpadding="0" cellspacing="0" style="border-collapse: collapse" bordercolor="#111111" width="100%" class="vsdatatable">
      <tr>
        <td nowrap colspan="2" class="vsdataoverskrift">Strømhastighed</td>
      </tr>
      <tr>
        <td nowrap class="vsdatavalue" valign="bottom">1,5</td>
        <td nowrap valign="bottom" class="vsdatavaluev">knob</td>
      </tr>
      
    </table>
          </td>
          <td width="25%" align="center">
    <table border="0" cellpadding="0" cellspacing="0" style="border-collapse: collapse" bordercolor="#111111" width="100%" class="vsdatatable">
      <tr>
        <td nowrap colspan="2" class="vsdataoverskrift">Middel vindhastighed </td>
      </tr>
      <tr>
        <td nowrap class="vsdatavalue" valign="bottom">12,9</td>
        <td nowrap valign="bottom" class="vsdatavaluev">m/s</td>
      </tr>
      
    </table>
          </td>
          <td width="25%" align="center">
    <table border="0" cellpadding="0" cellspacing="0" style="border-collapse: collapse" bordercolor="#111111" width="100%" class="vsdatatable">
      <tr>
        <td nowrap colspan="3" class="vsdataoverskrift">Middel vindretning</td>
      </tr>
      <tr>
        <td nowrap align="center"></td>
        <td nowrap class="vsdatavalue" valign="bottom">SV</td>
        <td nowrap valign="bottom" class="vsdatavaluev">218°</td>
      </tr>
    </table>
          </td>
          <td width="25%" align="center">
    <table border="0" cellpadding="0" cellspacing="0" style="border-collapse: collapse" bordercolor="#111111" width="100%" class="vsdatatable">
   <tr>
        <td nowrap colspan="2" class="vsdataoverskrift">Middel Bølgehøjde</td>
      </tr>
      <tr>
        <td nowrap class="vsdatavalue" valign="bottom">1,05</td>
        <td nowrap valign="bottom" class="vsdatavaluev">m</td>
      </tr>
    </table>
          </td>
        </tr>
        <!--3***********************************************************-->
        <tr>
          <td width="25%" align="center">
          <table border="0" cellpadding="0" cellspacing="0" style="border-collapse: collapse" bordercolor="#111111" width="100%" class="vsdatatable">
     <tr>
        <td nowrap colspan="2" class="vsdataoverskrift">Luft Temperatur
        </td>
      </tr>
      <tr>
        <td nowrap class="vsdatavalue" valign="bottom">10,7</td>
        <td nowrap valign="bottom" class="vsdatavaluev">°C</td>
      </tr>
    </table>
          </td>
          <td width="25%" align="center">
    <table border="0" cellpadding="0" cellspacing="0" style="border-collapse: collapse" bordercolor="#111111" width="100%" class="vsdatatable">
      <tr>
        <td nowrap colspan="2" class="vsdataoverskrift">Vindstød</td>
      </tr>
      <tr>
        <td nowrap class="vsdatavalue" valign="bottom">17,4</td>
        <td nowrap valign="bottom" class="vsdatavaluev">m/s</td>
      </tr>
      
    </table>
          </td>
          <td width="25%" align="center">
          <table border="0" cellpadding="0" cellspacing="0" style="border-collapse: collapse" bordercolor="#111111" width="100%" class="vsdatatable">
      <tr>
        <td nowrap colspan="2" class="vsdataoverskrift">Barometer</td>
      </tr>
      <tr>
        <td nowrap class="vsdatavalue" valign="bottom">1007</td>
        <td nowrap valign="bottom" class="vsdatavaluev">hPA</td>
      </tr>
      
    </table>
          </td>
          <td width="25%" align="center">
    <table border="0" cellpadding="0" cellspacing="0" style="border-collapse: collapse" bordercolor="#111111" width="100%" class="vsdatatable">
      <tr>
        <td nowrap colspan="2" class="vsdataoverskrift">Bølgeperiode</td>
      </tr>
      <tr>
        <td nowrap class="vsdatavalue" valign="bottom">5,7</td>
        <td nowrap valign="bottom" class="vsdatavaluev">sek</td>
      </tr>
    </table>
          </td>
        </tr>
        <!--4***********************************************************-->
        <tr>
          <td width="25%" align="center">
         <table border="0" cellpadding="0" cellspacing="0" style="border-collapse: collapse" bordercolor="#111111" width="100%" class="vsdatatable">
          <tr>
         <td width="25%" align="center">
          
          <br>
          <input onclick="javascript:self.close();" type="button" value="Luk Vinduet" name="button">
          <br>
          <br>
          <input type="submit" value="  Se kurver  " onClick="tooltip('stat.asp','Vejrstation')" name="button">
    
          </td>
      </tr>
    </table>
          </td>
          <td width="25%" align="center">
    <table border="0" cellpadding="0" cellspacing="0" style="border-collapse: collapse" bordercolor="#111111" width="100%" class="vsdatatable">
          <tr>
         <td width="25%" align="center">
          
          <br>
          
          <br>
          <br>
          
    
          </td>
      </tr>
    </table>
          </td>
          <td width="25%" align="center">
          <table border="0" cellpadding="0" cellspacing="0" style="border-collapse: collapse" bordercolor="#111111" width="100%" class="vsdatatable">
          <tr>
         <td width="25%" align="center">
          
          <br>
          
          <br>
          <br>
          
    
          </td>
      </tr>
    </table>
          </td>
          <td width="25%" align="center">
  <table border="0" cellpadding="0" cellspacing="0" style="border-collapse: collapse" bordercolor="#111111" width="100%" class="vsdatatable">
          <tr>
         <td width="25%" align="center">
          
          <br>
          
          <br>
          <br>
          
    
          </td>
      </tr>
    </table>
          </td>
        </tr>
        <!--5***********************************************************-->
        <tr>
          <td width="100%" align="center" colspan="4">
          <p align="center"><b>Senest opdateret : 07. april 2024 kl. 10:51
          </b></td>
        </tr>
        <tr>
          <td width="100%" align="center" colspan="4">
          <p align="center"><b>Få vejrdata på mobiltelefon på http://mobil.vejret-hanstholm.dk<br>
          </b></td>
        </tr>
      </table>
      </td>
    </tr>
    
    </table>
  </center>
</div>
</body>
</html>
"""
