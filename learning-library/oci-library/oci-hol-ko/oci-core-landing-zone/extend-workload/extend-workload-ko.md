# Landing Zone에 네트워크 배포

## 소개

워크로드를 배포하는 데 필요한 Landing Zone의 기본 골격을 만들었습니다. 이 실습에는 워크로드 자체는 포함되지 않습니다. 컴파트먼트, 그룹, 정책을 포함한 모든 IAM 요구 사항도 충족했습니다. 이제 워크로드가 클라이언트 및 구성 요소와 통신할 수 있어야 합니다. 하나 이상의 Virtual Cloud Network를 사용하면 이를 수행할 수 있습니다.

### 목표

- 구성 변수를 변경하여 Landing Zone을 수정하는 방법 학습
- 구성을 제자리에서 plan 및 apply하여 3계층 네트워크 생성
- 네트워크 리소스 검사

## 작업 1: 네트워크 변수 구성

Landing Zone을 정의하는 데 사용했던 구성으로 돌아가야 합니다. 구성 변수를 수정하여 Landing Zone에 추가될 네트워크를 선언할 수 있습니다.

1. 이전 실습에서 배포한 *Resource Manager Stack*의 *Stacks* 메뉴에서 *Resources* 아래의 __Variables__를 선택합니다.
1. __Edit Variables__ 버튼을 클릭합니다. 변수 양식이 채워지는 데 잠시 걸릴 수 있습니다.

    ![Resource Manager Stack에서 강조 표시된 버튼이 있는 변수 편집 창](./images/edit-variables-btn.png "Edit Variables 버튼 선택")

1. stack 변수의 *Configuration Options* 섹션에서 __Define Network Topology?__ 체크박스를 선택합니다.

    ![Define Network Topology?가 선택됨](./images/define-network.png "Define Networking? 버튼이 선택되어 있는지 확인")

1. 네 개의 Networking 섹션이 표시됩니다. *Networking - Three Tier VCNs*로 이동하여 __Add Three-Tier VCN (label: TT-VCN-1)?__ 버튼을 선택합니다. VCN의 표시 이름은 *VCN Name (label: TT-VCN-1)* 필드를 사용하여 구성할 수 있습니다. 그렇지 않으면 VCN 이름은 기본적으로 *TT-VCN-1*이 됩니다. 네트워크 CIDR 블록은 *List of CIDR Blocks* 필드에서 변경할 수 있습니다. *Customize VCN Subnets?*에서 추가 사용자 지정을 할 수 있지만, 이 실습 범위를 벗어납니다.

    ![3계층 네트워크 옵션](./images/network-config.png "여기에서 네트워크 구성")

1. __Next__ 버튼을 선택하여 *Review* 페이지로 이동합니다.
1. *Run apply*가 __선택되어 있지 않은지__ 확인하고 __Save changes__를 선택합니다.

## 작업 2: 업데이트된 구성 Plan 및 Apply

새 구성이 준비되었으므로 plan 및 apply 프로세스를 통해 네트워크를 배포합니다.

1. 구성을 저장한 후 *Stack details* 페이지에 있어야 합니다. __Plan__ 버튼을 클릭한 다음 __Plan__을 다시 클릭합니다.
1. plan 로그를 확인하여 리소스가 추가되고 있는지, 변경되거나 삭제되는 리소스가 없는지 확인합니다. 이는 리소스가 종료되고 다시 생성되지 않고 제자리에서 배포가 이루어짐을 의미합니다.

    *참고: 추가할 리소스의 정확한 수는 아래 스크린샷과 다를 수 있습니다.*

    ![추가, 변경, 삭제될 리소스를 보여 주는 Plan 출력](./images/network-plan-output.png "X to add, 0 to change, 0 to destroy")

1. *Stack details* 페이지로 다시 이동하여 __Apply__ 버튼을 클릭합니다.
1. __Apply job plan resolution__ 드롭다운에서 방금 만든 *Plan*을 선택한 다음 __Apply__를 다시 클릭합니다.
1. *Apply*가 완료되면 로그를 검사하여 배포된 리소스가 구성에서 정의한 원하는 상태와 일치하는지 확인합니다.

    ![Apply 출력 로그](./images/network-apply-output.png "Apply가 올바르게 실행되었는지 확인")

## 작업 3: 변경 사항 검사

1. 콘솔 왼쪽 위 모서리의 기본 메뉴에서 *Networking* > *Virtual cloud networks*로 이동하여 새 3계층 VCN을 검사합니다. 네트워크 리소스를 보려면 network 컴파트먼트에 있는지 확인합니다.

    ![Virtual Cloud Network](./images/3-tier-vcn.png "3계층 VCN")

1. Three Tier VCN을 클릭하고 네트워크 세부 정보를 검사합니다. 서브넷, 라우트 테이블, 네트워크 보안 그룹 및 기타 객체가 네트워크용으로 생성되었음을 확인합니다. 이러한 리소스는 VCN이 동작하는 방식과 네트워크에 기본적으로 보안이 적용되는 방식을 결정합니다.

    ![VCN 서브넷 및 세부 정보](./images/subnets.png "VCN의 서브넷 및 기타 세부 정보")

1. (*선택 사항*) 기본 메뉴에서 *Networking* > *Network Visualizer*로 이동하여 네트워크 시각화를 확인합니다. 네트워크 시각화가 보이지 않으면 network 컴파트먼트가 현재 선택되어 있는지 확인합니다. 네트워크의 리소스가 통신할 수 있도록 세 가지 게이트웨이가 표시되어야 합니다. 웹 계층을 위한 IGW(Internet Gateway), App 및 DB 서브넷의 프라이빗 인터넷 접근을 위한 NAT(NAT gateway), 마지막으로 OCI 내부 서비스와의 프라이빗 통신을 위한 SGW(Service Gateway)입니다.

    ![Network Visualizer 이미지](./images/visualizer-output.png "Network Visualizer 출력")

이제 Landing Zone은 다음과 비슷한 모습입니다.

![3계층 네트워크 아키텍처](./images/arch-three-tier.png "3계층 네트워크 아키텍처")

다음 실습에서는 Core Landing Zone 네트워크의 복잡성 및 확장성을 높입니다.

## 감사의 말

- __작성자__ - KC Flynn
- __기여자__ - Andre Correa, Johannes Murmann, Josh Hammer, Olaf Heimburger
- __최종 업데이트/일자__ - KC Flynn, 2025년 9월
