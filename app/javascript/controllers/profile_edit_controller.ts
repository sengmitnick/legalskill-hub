import { Controller } from "@hotwired/stimulus"

/* eslint-disable max-len */
// 省市区数据（同 profile_setup_controller.js）
const REGIONS = {
  "北京市": { "北京市": ["东城区","西城区","朝阳区","丰台区","石景山区","海淀区","门头沟区","房山区","通州区","顺义区","昌平区","大兴区","怀柔区","平谷区","密云区","延庆区"] },
  "上海市": { "上海市": ["黄浦区","徐汇区","长宁区","静安区","普陀区","虹口区","杨浦区","闵行区","宝山区","嘉定区","浦东新区","金山区","松江区","青浦区","奉贤区","崇明区"] },
  "天津市": { "天津市": ["和平区","河东区","河西区","南开区","河北区","红桥区","东丽区","西青区","津南区","北辰区","武清区","宝坻区","滨海新区","宁河区","静海区","蓟州区"] },
  "重庆市": { "重庆市": ["渝中区","大渡口区","江北区","沙坪坝区","九龙坡区","南岸区","北碚区","綦江区","大足区","渝北区","巴南区","黔江区","长寿区","江津区","合川区","永川区","南川区","璧山区","铜梁区","潼南区","荣昌区","开州区","梁平区","武隆区"] },
  "广东省": { "广州市": ["荔湾区","越秀区","海珠区","天河区","白云区","黄埔区","番禺区","花都区","南沙区","从化区","增城区"], "深圳市": ["罗湖区","福田区","南山区","宝安区","龙岗区","盐田区","龙华区","坪山区","光明区"], "东莞市": ["莞城区","南城区","万江区","石碣镇"], "佛山市": ["禅城区","南海区","顺德区","三水区","高明区"], "珠海市": ["香洲区","斗门区","金湾区"], "惠州市": ["惠城区","惠阳区","博罗县","惠东县","龙门县"], "中山市": ["石岐区"], "江门市": ["蓬江区","江海区","新会区"], "汕头市": ["龙湖区","金平区","濠江区","潮阳区","潮南区","澄海区","南澳县"] },
  "浙江省": { "杭州市": ["上城区","拱墅区","西湖区","滨江区","萧山区","余杭区","临平区","钱塘区","富阳区","临安区","桐庐县","淳安县","建德市"], "宁波市": ["海曙区","江北区","北仑区","镇海区","鄞州区","奉化区","象山县","宁海县","余姚市","慈溪市"], "温州市": ["鹿城区","龙湾区","瓯海区","洞头区","永嘉县","平阳县","苍南县","文成县","泰顺县","瑞安市","乐清市","龙港市"], "嘉兴市": ["南湖区","秀洲区","嘉善县","海盐县","海宁市","平湖市","桐乡市"], "湖州市": ["吴兴区","南浔区","德清县","长兴县","安吉县"], "绍兴市": ["越城区","柯桥区","上虞区","新昌县","诸暨市","嵊州市"] },
  "江苏省": { "南京市": ["玄武区","秦淮区","建邺区","鼓楼区","浦口区","栖霞区","雨花台区","江宁区","六合区","溧水区","高淳区"], "苏州市": ["姑苏区","虎丘区","吴中区","相城区","吴江区","太仓市","常熟市","张家港市","昆山市"], "无锡市": ["梁溪区","滨湖区","惠山区","锡山区","新吴区","江阴市","宜兴市"], "常州市": ["天宁区","钟楼区","新北区","武进区","金坛区","溧阳市"] },
  "四川省": { "成都市": ["锦江区","青羊区","金牛区","武侯区","成华区","龙泉驿区","青白江区","新都区","温江区","双流区","郫都区","新津区","金堂县","大邑县","蒲江县","都江堰市","彭州市","邛崃市","崇州市","简阳市"], "绵阳市": ["涪城区","游仙区","安州区","三台县","盐亭县","梓潼县","北川县","平武县","江油市"], "德阳市": ["旌阳区","罗江区","中江县","广汉市","什邡市","绵竹市"] },
  "湖北省": { "武汉市": ["江岸区","江汉区","硚口区","汉阳区","武昌区","青山区","洪山区","东西湖区","汉南区","蔡甸区","江夏区","黄陂区","新洲区"], "宜昌市": ["西陵区","伍家岗区","点军区","猇亭区","夷陵区","远安县","兴山县","秭归县","长阳县","五峰县","宜都市","当阳市","枝江市"], "襄阳市": ["襄城区","樊城区","襄州区","南漳县","谷城县","保康县","老河口市","枣阳市","宜城市"] },
  "湖南省": { "长沙市": ["芙蓉区","天心区","岳麓区","开福区","雨花区","望城区","长沙县","宁乡市","浏阳市"], "株洲市": ["荷塘区","芦淞区","石峰区","天元区","渌口区","攸县","茶陵县","炎陵县","醴陵市"] },
  "河南省": { "郑州市": ["中原区","二七区","管城区","金水区","上街区","惠济区","中牟县","巩义市","荥阳市","新密市","新郑市","登封市"], "洛阳市": ["老城区","西工区","涧西区","伊滨区","吉利区","孟津区","新安县","栾川县","嵩县","汝阳县","宜阳县","洛宁县","伊川县","偃师区","汝州市"] },
  "山东省": { "济南市": ["历下区","市中区","槐荫区","天桥区","历城区","长清区","章丘区","济阳区","莱芜区","钢城区","平阴县","商河县"], "青岛市": ["市南区","市北区","黄岛区","崂山区","李沧区","城阳区","即墨区","胶州市","平度市","莱西市"] },
  "河北省": { "石家庄市": ["长安区","桥西区","新华区","井陉矿区","裕华区","藁城区","鹿泉区","栾城区","井陉县","正定县","行唐县","灵寿县","高邑县","深泽县","赞皇县","无极县","平山县","元氏县","赵县","辛集市","晋州市","新乐市"] },
  "陕西省": { "西安市": ["新城区","碑林区","莲湖区","灞桥区","未央区","雁塔区","阎良区","临潼区","长安区","高陵区","鄠邑区","蓝田县","周至县"] },
  "福建省": { "福州市": ["鼓楼区","台江区","仓山区","马尾区","晋安区","长乐区","闽侯县","连江县","罗源县","闽清县","永泰县","平潭县","福清市"], "厦门市": ["思明区","海沧区","湖里区","集美区","同安区","翔安区"] },
  "安徽省": { "合肥市": ["瑶海区","庐阳区","蜀山区","包河区","长丰县","肥东县","肥西县","庐江县","巢湖市"] },
  "辽宁省": { "沈阳市": ["沈河区","和平区","大东区","皇姑区","铁西区","苏家屯区","浑南区","沈北新区","于洪区","辽中区","康平县","法库县","新民市"] },
  "吉林省": { "长春市": ["南关区","宽城区","朝阳区","二道区","绿园区","双阳区","九台区","农安县","榆树市","德惠市","公主岭市"] },
  "黑龙江省": { "哈尔滨市": ["道里区","道外区","南岗区","香坊区","平房区","松北区","呼兰区","阿城区","双城区","依兰县","方正县","宾县","巴彦县","木兰县","通河县","延寿县","尚志市","五常市"] },
  "云南省": { "昆明市": ["五华区","盘龙区","官渡区","西山区","东川区","呈贡区","晋宁区","富民县","宜良县","石林县","嵩明县","禄劝县","寻甸县","安宁市"] },
  "贵州省": { "贵阳市": ["南明区","云岩区","花溪区","乌当区","白云区","观山湖区","开阳县","息烽县","修文县","清镇市"] },
  "山西省": { "太原市": ["小店区","迎泽区","杏花岭区","尖草坪区","万柏林区","晋源区","清徐县","阳曲县","娄烦县","古交市"] },
  "广西壮族自治区": { "南宁市": ["兴宁区","青秀区","江南区","西乡塘区","良庆区","邕宁区","武鸣区","隆安县","马山县","上林县","宾阳县","横州市"] },
  "内蒙古自治区": { "呼和浩特市": ["回民区","玉泉区","赛罕区","新城区","土默特左旗","托克托县","和林格尔县","清水河县","武川县"] },
  "新疆维吾尔自治区": { "乌鲁木齐市": ["天山区","沙依巴克区","新市区","水磨沟区","头屯河区","达坂城区","米东区","乌鲁木齐县"] },
  "甘肃省": { "兰州市": ["城关区","七里河区","西固区","安宁区","红古区","永登县","皋兰县","榆中县"] },
  "江西省": { "南昌市": ["东湖区","西湖区","青云谱区","青山湖区","新建区","红谷滩区","南昌县","安义县","进贤县"] },
  "海南省": { "海口市": ["秀英区","龙华区","琼山区","美兰区"] },
  "西藏自治区": { "拉萨市": ["城关区","堆龙德庆区","达孜区","林周县","当雄县","尼木县","曲水县","墨竹工卡县"] },
  "宁夏回族自治区": { "银川市": ["兴庆区","西夏区","金凤区","永宁县","贺兰县","灵武市"] },
  "青海省": { "西宁市": ["城东区","城中区","城西区","城北区","湟中区","大通县","湟源县"] }
}

type RegionData = Record<string, Record<string, string[]>>

export default class extends Controller {
  static targets = ["province", "city", "district"]

  declare readonly provinceTarget:  HTMLSelectElement
  declare readonly cityTarget:      HTMLSelectElement
  declare readonly districtTarget:  HTMLSelectElement

  connect() {
    this.populateProvinces()
    // 恢复已保存的值
    const savedProvince = this.provinceTarget.dataset.selected
    if (savedProvince) {
      this.provinceTarget.value = savedProvince
      this.onProvinceChange()
      const savedCity = this.cityTarget.dataset.selected
      if (savedCity) {
        this.cityTarget.value = savedCity
        this.onCityChange()
        const savedDistrict = this.districtTarget.dataset.selected
        if (savedDistrict) {
          this.districtTarget.value = savedDistrict
        }
      }
    }
  }

  populateProvinces() {
    const sel = this.provinceTarget
    const placeholder = sel.querySelector("option")
    sel.innerHTML = ""
    if (placeholder) sel.appendChild(placeholder)
    Object.keys(REGIONS).forEach(p => {
      const opt = document.createElement("option")
      opt.value = p
      opt.textContent = p
      sel.appendChild(opt)
    })
  }

  onProvinceChange() {
    const province = this.provinceTarget.value
    const citySel = this.cityTarget
    const districtSel = this.districtTarget

    citySel.innerHTML = '<option value="">请选择市</option>'
    districtSel.innerHTML = '<option value="">请选择区/县</option>'

    const regions = REGIONS as RegionData
    if (!province || !regions[province]) return
    Object.keys(regions[province]).forEach(c => {
      const opt = document.createElement("option")
      opt.value = c
      opt.textContent = c
      citySel.appendChild(opt)
    })

    // 律所自动填入：若有 pending city，自动选中并继续填区
    const pendingCity = this.provinceTarget.dataset.pendingCity
    const pendingDistrict = this.provinceTarget.dataset.pendingDistrict
    if (pendingCity) {
      citySel.value = pendingCity
      this.provinceTarget.dataset.pendingCity = ""
      // 触发市联动填区
      this.cityTarget.dataset.pendingDistrict = pendingDistrict || ""
      this.onCityChange()
    }
  }

  onCityChange() {
    const province = this.provinceTarget.value
    const city = this.cityTarget.value
    const districtSel = this.districtTarget
    const regions = REGIONS as RegionData

    districtSel.innerHTML = '<option value="">请选择区/县</option>'
    if (!province || !city || !regions[province]?.[city]) return

    regions[province][city].forEach(d => {
      const opt = document.createElement("option")
      opt.value = d
      opt.textContent = d
      districtSel.appendChild(opt)
    })

    // 律所自动填入：若有 pending district，自动选中
    const pendingDistrict = this.cityTarget.dataset.pendingDistrict
    if (pendingDistrict) {
      districtSel.value = pendingDistrict
      this.cityTarget.dataset.pendingDistrict = ""
    }
  }
}
