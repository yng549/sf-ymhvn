public class ConvertCurrencyToVietnamese {       
    
    //123 => một trăm hai ba đồng
    //1,123,000=>một triệu một trăm hai ba nghìn đồng
    //1,123,345,000 => một tỉ một trăm hai ba triệu ba trăm bốn lăm ngàn đồng
    
    //Viết hàm chuyển số hàng chục, giá trị truyền vào là số cần chuyển và một biến đọc phần lẻ hay không ví dụ 101 => một trăm lẻ một
    private static string DocHangChuc(integer so,boolean daydu)
    {
        string[] mNumText = 'không;một;hai;ba;bốn;năm;sáu;bảy;tám;chín'.Split(';');
        string chuoi = '';
        //Hàm để lấy số hàng chục ví dụ 21/10 = 2
        integer chuc = integer.valueof(System.Math.Floor((double)(so / 10)));
        //Lấy số hàng đơn vị bằng phép chia 21 % 10 = 1            
        integer donvi = integer.valueof(System.Math.mod(integer.valueof(so),10));
        //Nếu số hàng chục tồn tại tức >=20
        if (chuc>1) {
            chuoi = ' ' + mNumText[chuc] + ' mươi';
            if (donvi==1) {
                chuoi += ' mốt';
            }
        } else if (chuc==1) {//Số hàng chục từ 10-19
            chuoi = ' mười';
            if (donvi==1) {
                chuoi += ' một';
            }
        } else if (daydu && donvi>0) {//Nếu hàng đơn vị khác 0 và có các số hàng trăm ví dụ 101 => thì biến daydu = true => và sẽ đọc một trăm lẻ một
            chuoi = ' lẻ';
        }
        if (donvi==5 && chuc>=1) {//Nếu đơn vị là số 5 và có hàng chục thì chuỗi sẽ là ' lăm' chứ không phải là ' năm'
            chuoi += ' lăm';
        } else if (donvi>1||(donvi==1&&chuc==0)) {
            chuoi += ' ' + mNumText[ donvi ];
        }
        return chuoi;
    }
    
    private static string DocHangTram(integer so,boolean daydu)
    {
        string[] mNumText = 'không;một;hai;ba;bốn;năm;sáu;bảy;tám;chín'.Split(';');
        string chuoi = '';
        //Lấy số hàng trăm ví du 434 / 100 = 4 (hàm Floor sẽ làm tròn số nguyên bé nhất)
        integer tram = integer.valueof(Math.Floor((double)so/100));
        //Lấy phần còn lại của hàng trăm 434 % 100 = 34 (dư 34)
        so = System.Math.mod(integer.valueof(so),100);
        if (daydu || tram>0) {
            chuoi = ' ' + mNumText[tram] + ' trăm';
            chuoi += DocHangChuc(integer.valueof(so),true);
        } else {
            chuoi = DocHangChuc(so,false);
        }
        return chuoi;
    }
    
    private static string DocHangTrieu(integer so,boolean daydu)
    {
        string chuoi = '';
        //Lấy số hàng triệu
        integer trieu = integer.valueof(Math.Floor((double)so/1000000));
        //Lấy phần dư sau số hàng triệu ví dụ 2,123,000 => so = 123,000
        so = System.Math.mod(integer.valueof(so),1000000);
        if (trieu>0) {
            chuoi = DocHangTram(trieu,daydu) + ' triệu';
            daydu = true;
        }
        //Lấy số hàng nghìn
        integer nghin = integer.valueof(Math.Floor((double)so / 1000));
        //Lấy phần dư sau số hàng nghin 
        so = System.Math.mod(integer.valueof(so),1000);
        if (nghin>0) {
            chuoi += DocHangTram(nghin,daydu) + ' nghìn';
            daydu = true;
        }
        if (so>0) {
            chuoi += DocHangTram(so,daydu);
        }
        return chuoi;
    }
    
    public static string convertV(decimal so)
    {
        string[] mNumText = 'không;một;hai;ba;bốn;năm;sáu;bảy;tám;chín'.Split(';');
        if (so == 0)
            return mNumText[0];
        string chuoi = '', hauto = '';
        integer ty;
        string chuoi2 = '';
        Boolean daydu = false;
        Boolean laySoDuLan1 = true;
        do
        {
            //Lấy số hàng tỷ
            ty = integer.valueof(Math.Floor((double)so / 1000000000));
            //Lấy phần dư sau số hàng tỷ
            if (laySoDuLan1){  
                so = System.Math.mod(so.longValue(),1000000000);
                // Giá trị tối đa của integer là 2,147,483,647 nếu số > 2,147,483,647 math.mod sẽ ra kết quả sai
                //  so = System.Math.mod(integer.valueof(so),1000000000);
                laySoDuLan1 = false;
                
            }
            if (ty > 0)
            {System.debug('Ty: ' + ty);
             chuoi2 += DocHangTrieu(integer.valueof(ty), daydu) + ' tỷ';
             daydu= true;
             //hauto
            }
            else
            {
                System.debug('SO: ' + so);
                chuoi = chuoi2 + DocHangTrieu(integer.valueof(so), daydu) + hauto ;
            }
            // hauto = ' tỷ';
        } while (ty > 0);
        
        string strResult = chuoi ;
        System.debug(strResult);
        return strResult;
    }  
}