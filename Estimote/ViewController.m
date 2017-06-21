//
//  ViewController.m
//  Estimote
//
//  Created by Muralisankar on 19/06/17.
//  Copyright © 2017 BNPP. All rights reserved.
//

#import "ViewController.h"
#import <EstimoteSDK/EstimoteSDK.h>
@import SocketIO;

@interface ViewController ()<ESTBeaconManagerDelegate,ESTBeaconConnectionDelegate,UIGestureRecognizerDelegate,UITextFieldDelegate,UIPickerViewDataSource, UIPickerViewDelegate>
{
    UITapGestureRecognizer *tapRecognizer;
    NSArray *listOfBuildings;
    NSArray *listOfFloor;
    UIPickerView *buildingPickerView;
    UIPickerView *floorPickerView;
    NSOutputStream *outputStream;
}

@property (nonatomic) ESTBeaconManager *beaconMgr;
@property (nonatomic) CLBeaconRegion *beaconRegion;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UITextField *building;
@property (weak, nonatomic) IBOutlet UITextField *floor;
@property (weak, nonatomic) IBOutlet UITextField *macid;
@property (nonatomic,strong) SocketIOClient* socket;

@end

@implementation ViewController

#define UUID        @"B9407F30-F5F8-466E-AFF9-25556B57FE6D"
#define MOVE_UP     @"move_up"
#define MOVE_DOWN   @"move_down"

#define SOCKET_URL  @"https://easy-office.herokuapp.com/"

#pragma mark- View Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    //Clear Text Fields
    [self clearTextField];
    //Set Delegate For Properties
    [self setDelegateForProperties];
    //Set Done For Text Field
    [self setDoneButtonForTextField];
    //Initialize Gesture
    [self initializeGesture];
    //Populate List of Buildings & Floors
    [self populateList];
    //Initialize Socket Stream
    [self initializeSocketStream];
    
    //Initialize ESTBeacon Manager
    self.beaconMgr = [ESTBeaconManager new];
    self.beaconMgr.delegate = self;
    
    //Start Monitoring Region with Specific UUID, Major and Minor Value
    self.beaconRegion = [[CLBeaconRegion alloc]
                         initWithProximityUUID:[[NSUUID alloc]
                                                initWithUUIDString:UUID]
                         identifier:@"ranged region"];

    //This will ask for user to promte with Allowing Location Access When App is Opened
    [self.beaconMgr requestWhenInUseAuthorization];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //Start the Ranging
    if([self.beaconMgr isAuthorizedForRanging])
    {
        [self.beaconMgr startRangingBeaconsInRegion:self.beaconRegion];
    }
    else
    {
        _statusLabel.text = @"No Beacons are in Range, Please make sure Beacons are nearby";
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    //Stop the Ranging
    [self.beaconMgr stopRangingBeaconsInRegion:self.beaconRegion];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark- Initialize Gesture

-(void)initializeGesture
{
    //Add Gesture Recogonizer
    tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped)];
    tapRecognizer.numberOfTapsRequired = 1;
    tapRecognizer.delegate=self;
    [self.view addGestureRecognizer:tapRecognizer];
}

-(void)viewTapped
{
    [_building resignFirstResponder];
    [_floor resignFirstResponder];
    [_macid resignFirstResponder];
}


#pragma mark- Set Delegate

-(void)setDelegateForProperties
{
    //Text Field Delegates
    [_building setDelegate:(id)self];
    [_floor setDelegate:(id)self];
    [_macid setDelegate:(id)self];
}

-(void)setDoneButtonForTextField
{
    UIToolbar* keyboardDoneButtonView = [[UIToolbar alloc] init];
    keyboardDoneButtonView.barStyle = UIBarStyleBlack;
    keyboardDoneButtonView.translucent = NO;
    
    UIBarButtonItem* doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                    style:UIBarButtonItemStyleDone target:self
                                                                   action:@selector(pickerDoneClicked)] ;
    doneButton.tintColor = [UIColor darkGrayColor];
    [keyboardDoneButtonView setItems:[NSArray arrayWithObjects:doneButton, nil]];
    
    _building.inputAccessoryView = keyboardDoneButtonView;
    _floor.inputAccessoryView = keyboardDoneButtonView;
}


#pragma mark - Populate Array List

-(void)populateList
{
    listOfBuildings = [[NSArray alloc] initWithObjects:@"Building 1",@"Building 2",@"Building 3",@"Building 4",@"Building 5",@"Building 6",@"Building 7",@"Building 8",@"Building 9",@"Building 10", nil];
    listOfFloor = [[NSArray alloc] initWithObjects:@"Floor 1",@"Floor 2",@"Floor 3",@"Floor 4",@"Floor 5",@"Floor 6",@"Floor 7",@"Floor 8",@"Floor 9",@"Floor 10",@"Floor 11",@"Floor 12",@"Floor 13",@"Floor 14",@"Floor 15", nil];
}

#pragma mark - Initialize Socket Stream

-(void)initializeSocketStream
{
    NSURL* url = [[NSURL alloc] initWithString:SOCKET_URL];
    _socket = [[SocketIOClient alloc] initWithSocketURL:url config:@{@"log": @YES, @"forcePolling": @YES}];

    [_socket on:@"connect" callback:^(NSArray* data, SocketAckEmitter* ack) {
        NSLog(@"socket connected");
    }];
    [_socket connect];
   
}

#pragma mark- Picker View Delegate

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    if(pickerView==buildingPickerView)
    {
        return [listOfBuildings count];
    }
    else if(pickerView==floorPickerView)
    {
        return [listOfFloor count];
    }
    
    return 0;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component;
{
    if(pickerView==buildingPickerView)
    {
        return [listOfBuildings objectAtIndex:row];
    }
    else if(pickerView==floorPickerView)
    {
        return [listOfFloor objectAtIndex:row];
    }
    
    return 0;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if(pickerView==buildingPickerView)
    {
        _building.text = [listOfBuildings objectAtIndex:row];
    }
    else if(pickerView==floorPickerView)
    {
        _floor.text = [listOfFloor objectAtIndex:row];
    }
}

-(void)pickerDoneClicked
{
    [_building resignFirstResponder];
    [_floor resignFirstResponder];
}


#pragma mark - Text Field Delegates

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if (textField == _macid) {
        return NO;
    }
    else if (textField ==_building) {
        //Initialize Picker View
        buildingPickerView = [[UIPickerView alloc] init];
        //Picker View
        buildingPickerView.dataSource = self;
        buildingPickerView.delegate = self;
        _building.inputView = buildingPickerView;
    }
    else if (textField ==_floor) {
        //Initialize Picker View
        floorPickerView = [[UIPickerView alloc] init];
        //Picker View
        floorPickerView.dataSource = self;
        floorPickerView.delegate = self;
        _floor.inputView = floorPickerView;
    }
    
    
    return YES;
}

#pragma mark- Text Field Utility

-(void)clearTextField
{
    _building.text = @"";
    _floor.text = @"";
    _macid.text = @"";
}

#pragma mark - IBAction Up Down 

- (IBAction)upPressed:(id)sender {
    [self performActionForButton:MOVE_UP];
}

- (IBAction)downPressed:(id)sender {
    [self performActionForButton:MOVE_DOWN];
}

-(void)performActionForButton:(NSString *)processName
{
    @try {
        if([_building.text isEqualToString:@""] || [_floor.text isEqualToString:@""] || [_macid.text isEqualToString:@""])
        {
            [self showAlertWithMessage:@"Fields can't be left empty" andTitle:@"Error"];
        }
        [_socket emit:processName with:@[@{@"Building": @"boreal",@"Floor": @(8),@"ScreenId": _macid.text}]];
    }
    @catch(NSException *exception){
        [self showAlertWithMessage:[NSString stringWithFormat:@"Exception in sending JSON Object : %@",[exception description]] andTitle:@"Exception"];
    }
}



#pragma mark - Utility Method

-(void)showAlertWithMessage:(NSString *)message andTitle:(NSString *)title
{
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:title
                                          message:message
                                          preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* ok = [UIAlertAction
                         actionWithTitle:@"Ok"
                         style:UIAlertActionStyleCancel
                         handler:^(UIAlertAction * action)
                         {
                             [alertController dismissViewControllerAnimated:YES completion:nil];
                         }];
    
    [alertController addAction:ok]; // add action to uialertcontroller
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark- Request Authorization Call Back Methods

//Checks For the Request Authorization Status
- (void)beaconManager:(id)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    switch (status) {
        case kCLAuthorizationStatusRestricted:
            _statusLabel.text = @"AuthorizationStatusRestrictedn";
            break;
        case kCLAuthorizationStatusDenied:
            _statusLabel.text = @"AuthorizationStatusDenied";
            break;
        case kCLAuthorizationStatusAuthorizedAlways:
            _statusLabel.text = @"AuthorizationStatusAuthorizedAlways";
            break;
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            _statusLabel.text = @"AuthorizationStatusAuthorizedWhenInUse";
            break;

        default:
            break;
    }
}

#pragma mark- Range Beacon Call Back Methods

- (void)beaconManager:(id)manager
      didRangeBeacons:(NSArray<CLBeacon *> *)beacons
             inRegion:(CLBeaconRegion *)region
{
    //Update Status Label
    _statusLabel.text = @"Beacon In Range";
    //Get the Major and Minor Value
    CLBeacon *foundBeacon = [beacons firstObject];
    // You can retrieve the beacon data from its properties
    NSString *uuid = foundBeacon.proximityUUID.UUIDString;
    NSString *major = [NSString stringWithFormat:@"%@", foundBeacon.major];
    NSString *minor = [NSString stringWithFormat:@"%@", foundBeacon.minor];

    if([major isEqualToString:@""] || [major isEqualToString:@"null"] || [minor isEqualToString:@""] || [minor isEqualToString:@"null"])
    {
        _macid.text = @"";
        _statusLabel.text = @"No Beacon in Range";
    }
    _macid.text = @"";
    _macid.text = [NSString stringWithFormat:@"%@-%@", foundBeacon.major,foundBeacon.minor];
}

#pragma mark - Dealloc

-(void)dealloc
{
    NSLog(@"Dealloc Called");
}

@end
