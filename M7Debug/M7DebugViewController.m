//
//  M7DebugViewController.m
//  M7Debug
//
//  Created by Kevin on 1/2/14.
//  Copyright (c) 2014 Kevin. All rights reserved.
//

#import "M7DebugViewController.h"

@interface M7DebugViewController()

@property (strong, nonatomic) NSMutableArray *objects;
@property (strong, nonatomic) NSTimer *refreshTimer;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSString *notAvailableSymbol;

@property (strong, nonatomic) CMMotionActivityManager *activityManager;

@property (strong, nonatomic) CMStepCounter *stepCounter;

@property (nonatomic, readwrite, getter = isSpeaking) BOOL speaking;
@property (strong, nonatomic) AVSpeechSynthesizer *speechSynthesizer;

@end

@implementation M7DebugViewController

- (NSMutableArray *)objects
{
	if (!_objects)
	{
		_objects = [[NSMutableArray alloc] initWithCapacity:4];
		
		[_objects addObject:[self cellWithLabel:@"Activity"]];           // 0
		[_objects addObject:[self cellWithLabel:@"Confidence"]];         // 1
		[_objects addObject:[self cellWithLabel:@"Start Time"]];         // 2
		[_objects addObject:[self cellWithLabel:@"Steps Since Launch"]]; // 3
	}
	return _objects;
}

- (UITableViewCell *)cellWithLabel:(NSString *)label
{
	return [self cellWithLabel:label withDetailLabel:self.notAvailableSymbol];
}

- (UITableViewCell *)cellWithLabel:(NSString *)label withDetailLabel:(NSString *)detailLabel
{
	UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"keyLeft"];
	cell.textLabel.text = label;
	cell.detailTextLabel.text = detailLabel;
	
	return cell;
}

- (NSString *)notAvailableSymbol
{
	if (!_notAvailableSymbol)
	{
		_notAvailableSymbol = @"—";
	}
	return _notAvailableSymbol;
}

- (CMMotionActivityManager *)activityManager
{
	if (!_activityManager && [CMMotionActivityManager isActivityAvailable])
	{
		_activityManager = [[CMMotionActivityManager alloc] init];
	}
	return _activityManager;
}

- (CMStepCounter *)stepCounter
{
	if (!_stepCounter && [CMStepCounter isStepCountingAvailable])
	{
		_stepCounter = [[CMStepCounter alloc] init];
	}
	return _stepCounter;
}

- (AVSpeechSynthesizer *)speechSynthesizer
{
	if (!_speechSynthesizer)
	{
		_speechSynthesizer = [[AVSpeechSynthesizer alloc] init];
	}
	return _speechSynthesizer;
}

- (void)awakeFromNib
{
	[super awakeFromNib];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	/* uncomment to set navigation bar color
	self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0.0 green:0.4 blue:0.8 alpha:1.0];
	self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
	self.navigationController.navigationBar.barStyle = UIBarStyleBlack;*/
}

- (void)viewWillAppear:(BOOL)animated
{
	if (self.activityManager != nil)
	{
		// Block that will handle activity updates. 
		// Generates strings from CMMotionActivity and applies them to the view.
		CMMotionActivityHandler activityHandler = ^(CMMotionActivity *activity)
		{
			// Current activity
			NSString *activityName = @"";
			if (activity.stationary) activityName = @"Stationary";
			else if (activity.walking) activityName = @"Walking";
			else if (activity.running) activityName = @"Running";
			else if (activity.automotive) activityName = @"Automotive";
			else if (activity.unknown) activityName = @"Unknown";
			
			[self setDetailTextAtIndex:0 toText:activityName];
			
			// Confidence
			NSString *confidence = @"";
			if (activity.confidence == CMMotionActivityConfidenceHigh) confidence = @"High";
			else if (activity.confidence == CMMotionActivityConfidenceMedium) confidence = @"Medium";
			else if (activity.confidence == CMMotionActivityConfidenceLow) confidence = @"Low";
			
			[self setDetailTextAtIndex:1 toText:confidence];
			
			// Start date
			NSString *startTime = [NSDateFormatter localizedStringFromDate:activity.startDate dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterMediumStyle];
			
			[self setDetailTextAtIndex:2 toText:startTime];
			
			// Apply to view
			[self.tableView reloadData];
			
			// Optionally, speak to the user about the change
			if (self.isSpeaking)
			{
				// Construct what we're going to say (Example: "Automotive confidence medium")
				NSString *changeDescription = [activityName stringByAppendingString:@" confidence "];
				changeDescription = [changeDescription stringByAppendingString:confidence];
				// Say it
				[self.speechSynthesizer speakUtterance:[AVSpeechUtterance speechUtteranceWithString:changeDescription]];
			}
		};
		
		[self.activityManager startActivityUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:activityHandler];
	}
	
	if (self.stepCounter != nil)
	{
		CMStepUpdateHandler stepHandler = ^(NSInteger numberOfSteps, NSDate *timestamp, NSError *error)
		{
			// Generate NSString representing number of steps or error
			NSString *stepsText;
			if (error != nil)
			{
				stepsText = @"Error";
				NSLog(@"CMStepUpdateHandler received error: %@", [error description]); // TODO: replace w/ uialertview?
			}
			else
			{
				stepsText = [NSString stringWithFormat:@"%ld", numberOfSteps];
			}
			
			// Apply to view
			[[[self.objects objectAtIndex:3] detailTextLabel] setText:stepsText];
			[self.tableView reloadData];
			
			// Optionally, speak to the user about the change
			if (self.isSpeaking)
			{
				NSString *changeDescription = [stepsText stringByAppendingString:@" steps"];
				[self.speechSynthesizer speakUtterance:[AVSpeechUtterance speechUtteranceWithString:changeDescription]];
			}
		};
		
		// Attach the step handler block to the step manager. Update every time there is a new step.
		[self.stepCounter startStepCountingUpdatesToQueue:[NSOperationQueue mainQueue] updateOn:1 withHandler:stepHandler];
	}
}

- (void)viewDidDisappear:(BOOL)animated
{
	[self.activityManager stopActivityUpdates];
	[self.stepCounter stopStepCountingUpdates];
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (IBAction)toggleSpeaking:(UIBarButtonItem *)sender
{
	self.speaking = !self.speaking;
	sender.style = self.speaking ? UIBarButtonItemStyleDone : UIBarButtonItemStyleBordered;
}

- (void)setDetailTextAtIndex:(NSUInteger)index toText:(NSString *)text
{
	if (text == nil || [text isEqualToString:@""])
	{
		text = self.notAvailableSymbol;
	}
	((UITableViewCell *)[self.objects objectAtIndex:index]).detailTextLabel.text = text;
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [self.objects count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	//UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	// NSIndexPath works sort of like a tree. This gets the second layer. (index starts from 0)
	return [self.objects objectAtIndex:[indexPath indexAtPosition:1]];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	// No cells should be editable
	return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	/*if (editingStyle == UITableViewCellEditingStyleDelete)
	{
		[_objects removeObjectAtIndex:indexPath.row];
		[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
	} 
	else if (editingStyle == UITableViewCellEditingStyleInsert)
	{
		// Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
	}*/
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
	
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
	// Return NO if you do not want the item to be re-orderable.
	return YES;
}
*/

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([[segue identifier] isEqualToString:@"showDetail"])
	{
		/*  this is a single view app
		NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
		NSDate *object = _objects[indexPath.row];
		[[segue destinationViewController] setDetailItem:object];*/
	}
}

@end
